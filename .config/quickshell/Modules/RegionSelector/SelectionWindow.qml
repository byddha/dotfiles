import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../Config"
import "../../Services"
import "../../Utils"

PanelWindow {
    id: root

    property int action: RegionSelector.SnipAction.Copy
    signal dismiss
    signal actionChangeRequested(int newAction)

    visible: true
    color: "transparent"
    WlrLayershell.namespace: "bidshell:regionselector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Monitor info (snapshot)
    readonly property var monitorInfo: Compositor.monitorForScreen(screen)
    readonly property real monitorScale: monitorInfo?.scale ?? 1
    readonly property real monitorOffsetX: monitorInfo?.x ?? 0
    readonly property real monitorOffsetY: monitorInfo?.y ?? 0
    property int activeWorkspaceId: monitorInfo?.activeWorkspaceId ?? 0
    readonly property int specialWorkspaceId: (Compositor.monitors.find(m => m.name === screen?.name)?.specialWorkspace?.id) ?? 0
    readonly property int effectiveWorkspaceId: specialWorkspaceId !== 0 ? specialWorkspaceId : activeWorkspaceId

    // Screenshot paths
    readonly property string screenshotDir: "/tmp/bidshell-screenshots"
    readonly property string screenshotPath: `${screenshotDir}/region-${screen.name}.png`

    // Selection state
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property bool dragging: false

    // Region (settable for adjustment)
    property real regionX: 0
    property real regionY: 0
    property real regionWidth: 0
    property real regionHeight: 0

    // Adjustment mode (after initial drag, before confirming)
    property bool adjusting: false
    property bool editMode: false  // When true, snip opens in Swappy instead of copying
    property bool saveMode: false  // When true, save directly to file instead of clipboard
    property bool lensMode: false  // When true, send to Google Lens for visual search
    property bool ocrMode: false   // When true, extract text via Tesseract OCR
    property bool ocrAllLangs: false // When true, use all installed languages; otherwise English only
    property bool ocrTranslate: false // When true, open OCR result in Kagi Translate
    property string adjustHandle: ""  // Which handle is being dragged: "", "move", "nw", "ne", "sw", "se", "n", "s", "e", "w"
    property real adjustStartX: 0
    property real adjustStartY: 0
    property real adjustStartRegionX: 0
    property real adjustStartRegionY: 0
    property real adjustStartRegionW: 0
    property real adjustStartRegionH: 0

    // Window regions from HyprlandData, sorted for proper z-order (floating above tiled)
    readonly property var windowRegions: {
        const workspaceWindows = Compositor.windowList.filter(w => w.workspace.id === root.effectiveWorkspaceId);

        // If any window is fullscreen or maximized, only show that window (others are occluded)
        // fullscreen: 1 = real fullscreen, 2 = maximized
        const fullscreenWindow = workspaceWindows.find(w => w.fullscreen > 0);
        if (fullscreenWindow) {
            return [
                {
                    at: [fullscreenWindow.at[0] - root.monitorOffsetX, fullscreenWindow.at[1] - root.monitorOffsetY],
                    size: fullscreenWindow.size,
                    class: fullscreenWindow.class,
                    title: fullscreenWindow.title,
                    floating: fullscreenWindow.floating
                }
            ];
        }

        // Sort: floating windows first (higher z-order), then tiled
        // Among floating windows, smaller ones first (easier to target, likely on top)
        const sorted = [...workspaceWindows].sort((a, b) => {
            if (a.floating && !b.floating)
                return -1;
            if (!a.floating && b.floating)
                return 1;
            // Both floating: smaller area first (higher priority for targeting)
            if (a.floating && b.floating) {
                const areaA = a.size[0] * a.size[1];
                const areaB = b.size[0] * b.size[1];
                return areaA - areaB;
            }
            return 0;
        });

        return sorted.map(w => ({
                    at: [w.at[0] - root.monitorOffsetX, w.at[1] - root.monitorOffsetY],
                    size: w.size,
                    class: w.class,
                    title: w.title,
                    floating: w.floating
                }));
    }

    // Floating windows only (for computing cutouts in tiled windows)
    readonly property var floatingWindows: windowRegions.filter(w => w.floating)

    // Targeted window region (for click-to-select)
    property real targetedRegionX: -1
    property real targetedRegionY: -1
    property real targetedRegionWidth: 0
    property real targetedRegionHeight: 0
    property bool hasTargetedRegion: targetedRegionX >= 0 && targetedRegionY >= 0

    // Preparation state
    property bool preparationDone: false
    property bool snipping: false

    // Tracks whether the cursor is on THIS monitor. Seeded from a Compositor
    // probe on show (containsMouse alone isn't reliable — Wayland doesn't send
    // an enter event when a sibling MouseArea just becomes visible, so hover
    // starts out false until the user wiggles the mouse). Key-press guards
    // use this instead of root.cursorOnThisMonitor directly.
    property bool cursorOnThisMonitor: false

    function _probeCursorMonitor() {
        if (!root.visible || !root.preparationDone)
            return;
        Compositor.getCursorPosition((globalX, globalY) => {
            const localX = globalX - root.monitorOffsetX;
            const localY = globalY - root.monitorOffsetY;
            root.cursorOnThisMonitor = localX >= 0 && localX < root.width && localY >= 0 && localY < root.height;
            root.updateTargetedRegion(localX, localY);
        });
    }

    // Timing instrumentation
    property double _t0: Date.now()
    function _tlog(label) {
        Logger.trace(`RegionSelector[${screen.name}] +${Date.now() - root._t0}ms ${label}`);
    }

    onVisibleChanged: root._tlog(`visible=${visible}`)

    // Ensure screenshot temp directory exists (saveToFile won't mkdir)
    Process {
        id: mkdirProc
        running: true
        command: ["mkdir", "-p", root.screenshotDir]
        onRunningChanged: root._tlog(`mkdir running=${running}`)
    }

    // UI is interactive as soon as the screencopy buffer arrives (~15ms).
    // We do NOT save a full-screen PNG at startup — encoding a 3440x1440 PNG
    // takes >1s and the user never needs the full file, only the crop they
    // select. Instead, snip() and shrinkToContent() each grab a cropped region
    // on demand via the `regionCrop` ShaderEffectSource below.
    Connections {
        target: screencopyView
        function onHasContentChanged() {
            root._tlog(`ScreencopyView hasContent=${screencopyView.hasContent}`);
            if (!screencopyView.hasContent || root.preparationDone)
                return;
            root.preparationDone = true;
            Logger.debug("RegionSelector: screencopy ready for", root.screen.name);
        }
    }

    // Hidden cropper used by snip() / shrinkToContent() to extract a cropped
    // PNG on demand. Rendered behind everything (z: -100) so the user never
    // sees it. Size/sourceRect are set per-grab in `_grabRegionToFile`.
    ShaderEffectSource {
        id: regionCrop
        z: -100
        x: 0
        y: 0
        visible: root.preparationDone
        live: false
        sourceItem: screencopyView

        property real grabX: 0
        property real grabY: 0
        property real grabW: 1
        property real grabH: 1
        property real grabScale: 1

        sourceRect: Qt.rect(grabX, grabY, grabW, grabH)
        width: Math.max(1, Math.round(grabW * grabScale))
        height: Math.max(1, Math.round(grabH * grabScale))
        textureSize: Qt.size(width, height)
    }

    // Grab the given logical-coord region to `screenshotPath` at native
    // resolution, then call onDone(true|false).
    function _grabRegionToFile(rx, ry, rw, rh, onDone) {
        if (mkdirProc.running) {
            Qt.callLater(() => root._grabRegionToFile(rx, ry, rw, rh, onDone));
            return;
        }
        if (rw <= 0 || rh <= 0) {
            Logger.error("RegionSelector: invalid region", rx, ry, rw, rh);
            onDone(false);
            return;
        }
        regionCrop.grabScale = root.monitorScale;
        regionCrop.grabX = rx;
        regionCrop.grabY = ry;
        regionCrop.grabW = rw;
        regionCrop.grabH = rh;
        regionCrop.scheduleUpdate();
        const nativeW = regionCrop.width;
        const nativeH = regionCrop.height;
        // One tick so ShaderEffectSource re-captures with the new sourceRect
        Qt.callLater(() => {
            const t0 = Date.now();
            const ok = regionCrop.grabToImage(result => {
                if (!result) {
                    Logger.error("RegionSelector: region grabToImage returned null");
                    onDone(false);
                    return;
                }
                const saved = result.saveToFile(root.screenshotPath);
                if (!saved) {
                    Logger.error("RegionSelector: region saveToFile failed", root.screenshotPath);
                    onDone(false);
                    return;
                }
                root._tlog(`region saved (${nativeW}x${nativeH}) in ${Date.now() - t0}ms`);
                onDone(true);
            }, Qt.size(nativeW, nativeH));
            if (!ok) {
                Logger.error("RegionSelector: region grabToImage returned false");
                onDone(false);
            }
        });
    }

    // Snip process
    Process {
        id: snipProc
    }

    // Shrink-to-content process. The file at screenshotPath is now the cropped
    // region (not the full screen), so the python script receives (0, 0, w, h)
    // and we add cropOffset{X,Y} back to its output to convert crop-local
    // native coords → screen-native → logical.
    Process {
        id: shrinkProc
        property real scale: root.monitorScale
        property real cropOffsetX: 0
        property real cropOffsetY: 0

        stdout: SplitParser {
            onRead: data => {
                try {
                    const result = JSON.parse(data.trim());
                    if (result.error) {
                        Logger.error("Shrink-to-content error:", result.error);
                        return;
                    }
                    root.regionX = (result.x + shrinkProc.cropOffsetX) / shrinkProc.scale;
                    root.regionY = (result.y + shrinkProc.cropOffsetY) / shrinkProc.scale;
                    root.regionWidth = result.width / shrinkProc.scale;
                    root.regionHeight = result.height / shrinkProc.scale;
                    Logger.debug("Shrink-to-content: new bounds", result);
                } catch (e) {
                    Logger.error("Shrink-to-content parse error:", e, data);
                }
            }
        }
    }

    function shrinkToContent() {
        if (!root.adjusting || root.regionWidth <= 0 || root.regionHeight <= 0)
            return;

        const rx = root.regionX;
        const ry = root.regionY;
        const rw = root.regionWidth;
        const rh = root.regionHeight;
        const scale = root.monitorScale;
        const nativeRw = Math.round(rw * scale);
        const nativeRh = Math.round(rh * scale);

        shrinkProc.cropOffsetX = Math.round(rx * scale);
        shrinkProc.cropOffsetY = Math.round(ry * scale);

        root._grabRegionToFile(rx, ry, rw, rh, success => {
            if (!success)
                return;
            shrinkProc.command = ["python", `${Qt.resolvedUrl("../../scripts/images/shrink_to_content.py").toString().replace("file://", "")}`, root.screenshotPath, "0", "0", String(nativeRw), String(nativeRh)];
            shrinkProc.running = true;
        });
    }

    function updateTargetedRegion(x, y) {
        const clickedWindow = root.windowRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });

        if (clickedWindow) {
            root.targetedRegionX = clickedWindow.at[0];
            root.targetedRegionY = clickedWindow.at[1];
            root.targetedRegionWidth = clickedWindow.size[0];
            root.targetedRegionHeight = clickedWindow.size[1];
        } else {
            root.targetedRegionX = -1;
            root.targetedRegionY = -1;
            root.targetedRegionWidth = 0;
            root.targetedRegionHeight = 0;
        }
    }

    function setRegionToTargeted() {
        root.regionX = root.targetedRegionX;
        root.regionY = root.targetedRegionY;
        root.regionWidth = root.targetedRegionWidth;
        root.regionHeight = root.targetedRegionHeight;
    }

    readonly property int handleHitArea: 16

    function getHandleAt(x, y) {
        if (!root.adjusting || root.regionWidth <= 0)
            return "";

        const rx = root.regionX;
        const ry = root.regionY;
        const rw = root.regionWidth;
        const rh = root.regionHeight;
        const h = root.handleHitArea;

        // Corner handles (check first, they have priority)
        if (Math.abs(x - rx) < h && Math.abs(y - ry) < h)
            return "nw";
        if (Math.abs(x - (rx + rw)) < h && Math.abs(y - ry) < h)
            return "ne";
        if (Math.abs(x - rx) < h && Math.abs(y - (ry + rh)) < h)
            return "sw";
        if (Math.abs(x - (rx + rw)) < h && Math.abs(y - (ry + rh)) < h)
            return "se";

        // Edge handles
        if (Math.abs(y - ry) < h && x > rx + h && x < rx + rw - h)
            return "n";
        if (Math.abs(y - (ry + rh)) < h && x > rx + h && x < rx + rw - h)
            return "s";
        if (Math.abs(x - rx) < h && y > ry + h && y < ry + rh - h)
            return "w";
        if (Math.abs(x - (rx + rw)) < h && y > ry + h && y < ry + rh - h)
            return "e";

        // Inside selection = move
        if (x >= rx && x <= rx + rw && y >= ry && y <= ry + rh)
            return "move";

        return "";
    }

    function handleAdjustment(x, y) {
        const dx = x - root.adjustStartX;
        const dy = y - root.adjustStartY;
        const minSize = 10;

        switch (root.adjustHandle) {
        case "move":
            root.regionX = Math.max(0, Math.min(root.width - root.regionWidth, root.adjustStartRegionX + dx));
            root.regionY = Math.max(0, Math.min(root.height - root.regionHeight, root.adjustStartRegionY + dy));
            break;
        case "nw":
            root.regionX = Math.min(root.adjustStartRegionX + root.adjustStartRegionW - minSize, root.adjustStartRegionX + dx);
            root.regionY = Math.min(root.adjustStartRegionY + root.adjustStartRegionH - minSize, root.adjustStartRegionY + dy);
            root.regionWidth = root.adjustStartRegionX + root.adjustStartRegionW - root.regionX;
            root.regionHeight = root.adjustStartRegionY + root.adjustStartRegionH - root.regionY;
            break;
        case "ne":
            root.regionY = Math.min(root.adjustStartRegionY + root.adjustStartRegionH - minSize, root.adjustStartRegionY + dy);
            root.regionWidth = Math.max(minSize, root.adjustStartRegionW + dx);
            root.regionHeight = root.adjustStartRegionY + root.adjustStartRegionH - root.regionY;
            break;
        case "sw":
            root.regionX = Math.min(root.adjustStartRegionX + root.adjustStartRegionW - minSize, root.adjustStartRegionX + dx);
            root.regionWidth = root.adjustStartRegionX + root.adjustStartRegionW - root.regionX;
            root.regionHeight = Math.max(minSize, root.adjustStartRegionH + dy);
            break;
        case "se":
            root.regionWidth = Math.max(minSize, root.adjustStartRegionW + dx);
            root.regionHeight = Math.max(minSize, root.adjustStartRegionH + dy);
            break;
        case "n":
            root.regionY = Math.min(root.adjustStartRegionY + root.adjustStartRegionH - minSize, root.adjustStartRegionY + dy);
            root.regionHeight = root.adjustStartRegionY + root.adjustStartRegionH - root.regionY;
            break;
        case "s":
            root.regionHeight = Math.max(minSize, root.adjustStartRegionH + dy);
            break;
        case "w":
            root.regionX = Math.min(root.adjustStartRegionX + root.adjustStartRegionW - minSize, root.adjustStartRegionX + dx);
            root.regionWidth = root.adjustStartRegionX + root.adjustStartRegionW - root.regionX;
            break;
        case "e":
            root.regionWidth = Math.max(minSize, root.adjustStartRegionW + dx);
            break;
        }
    }

    function snip() {
        if (root.regionWidth <= 0 || root.regionHeight <= 0) {
            // No region - try to find window at click position
            root.updateTargetedRegion(root.dragStartX, root.dragStartY);
            if (root.hasTargetedRegion) {
                root.setRegionToTargeted();
            } else {
                root.dismiss();
                return;
            }
        }

        const effectiveAction = root.action;

        const rwNative = Math.round(root.regionWidth * root.monitorScale);
        const rhNative = Math.round(root.regionHeight * root.monitorScale);

        // Record mode: wf-recorder captures live, no file grab needed.
        if (effectiveAction === RegionSelector.SnipAction.Record) {
            const slurpRegion = `${Math.round(root.regionX + root.monitorOffsetX)},${Math.round(root.regionY + root.monitorOffsetY)} ${rwNative}x${rhNative}`;
            snipProc.command = ["bash", "-c", `mkdir -p ~/Videos/Screencasts && wf-recorder -g '${slurpRegion}' -c h264_vaapi -f ~/Videos/Screencasts/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4`];
            Logger.info("RegionSelector: Starting recording");
            snipProc.startDetached();
            root.dismiss();
            return;
        }

        // Hide all UI chrome immediately (uiLayer.visible is gated on
        // !root.snipping). The PanelWindow + ScreencopyView stay alive briefly
        // so grabToImage has a rendered scene to read from, then dismiss once
        // the grab callback fires. User perceives the overlay as "gone now".
        root._grabRegionToFile(root.regionX, root.regionY, root.regionWidth, root.regionHeight, success => {
            if (!success) {
                root.dismiss();
                return;
            }
            const f = root.screenshotPath;
            const cleanup = `rm '${f}'`;
            let cmd;
            if (root.saveMode) {
                cmd = `mkdir -p ~/Pictures/Screenshots && cp '${f}' ~/Pictures/Screenshots/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png && ${cleanup}`;
                Logger.info("RegionSelector: Saving screenshot to ~/Pictures/Screenshots");
            } else if (root.lensMode) {
                cmd = `imageLink=$(curl -sF files[]=@'${f}' 'https://uguu.se/upload' | jq -r '.files[0].url') && xdg-open "https://lens.google.com/uploadbyurl?url=\${imageLink}" && ${cleanup}`;
                Logger.info("RegionSelector: Sending region to Google Lens");
            } else if (root.ocrMode) {
                const langFlag = root.ocrAllLangs ? `$(tesseract --list-langs 2>/dev/null | tail -n +2 | paste -sd+)` : "eng";
                const base = `tesseract '${f}' stdout -l ${langFlag}`;
                cmd = root.ocrTranslate ? `text=$(${base}) && printf '%s' "$text" | wl-copy && xdg-open "https://translate.kagi.com/?from=auto&to=&text=$(printf '%s' "$text" | jq -sRr @uri)" && ${cleanup}` : `${base} | wl-copy && ${cleanup}`;
                Logger.info(`RegionSelector: OCR (${root.ocrAllLangs ? "all" : "eng"}${root.ocrTranslate ? ", translate" : ""})`);
            } else if (root.editMode) {
                cmd = `swappy -f '${f}' && ${cleanup}`;
                Logger.info("RegionSelector: Opening region in swappy");
            } else {
                cmd = `wl-copy --type image/png < '${f}' && ${cleanup}`;
                Logger.info("RegionSelector: Copying region to clipboard");
            }
            snipProc.command = ["bash", "-c", cmd];
            snipProc.startDetached();
            root.dismiss();
        });
    }

    // Frozen screen capture — bare (no children) so grabToImage captures only
    // screen pixels, not the overlay UI. hasContentChanged fires after the
    // compositor delivers the first frame; the Connections block above flips
    // preparationDone then. File writes happen on demand via regionCrop.
    ScreencopyView {
        id: screencopyView
        anchors.fill: parent
        live: false
        paintCursor: false
        captureSource: root.screen
    }

    // Loading spinner shown between snip confirm and actual window dismiss.
    Text {
        anchors.centerIn: parent
        visible: root.snipping
        text: Icons.spinner
        font.family: Theme.fontFamilyIcons
        font.pixelSize: 160
        color: Theme.primary
        z: 10
        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: root.snipping
        }
    }

    // UI layer — sibling of screencopyView so grabToImage excludes it.
    // Hidden until the screencopy buffer is ready, and hidden again the instant
    // the user confirms a snip so the chrome disappears before the grab finishes.
    Item {
        id: uiLayer
        anchors.fill: parent
        visible: root.preparationDone && !root.snipping
        focus: root.visible && root.preparationDone && !root.snipping

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
                root.dismiss();
                break;
            case Qt.Key_Space:
            case Qt.Key_Return:
            case Qt.Key_Enter:
                // Confirm and copy to clipboard
                if (root.adjusting && root.regionWidth > 0 && root.regionHeight > 0 && root.cursorOnThisMonitor) {
                    root.snipping = true;
                    root.editMode = false;
                    root.lensMode = false;
                    root.ocrMode = false;
                    root.ocrTranslate = false;
                    root.snip();
                }
                break;
            case Qt.Key_E:
                // Confirm and open in Swappy for editing
                if (root.adjusting && root.regionWidth > 0 && root.regionHeight > 0 && root.cursorOnThisMonitor) {
                    root.snipping = true;
                    root.editMode = true;
                    root.lensMode = false;
                    root.ocrMode = false;
                    root.ocrTranslate = false;
                    root.snip();
                }
                break;
            case Qt.Key_S:
                if (event.modifiers & Qt.ControlModifier) {
                    // Ctrl+S: Save directly to file
                    if (root.adjusting && root.regionWidth > 0 && root.regionHeight > 0 && root.cursorOnThisMonitor) {
                        root.snipping = true;
                        root.saveMode = true;
                        root.editMode = false;
                        root.lensMode = false;
                        root.ocrMode = false;
                        root.ocrTranslate = false;
                        root.snip();
                    }
                } else {
                    // Plain S: Switch to Screenshot mode
                    root.actionChangeRequested(RegionSelector.SnipAction.Copy);
                }
                break;
            case Qt.Key_R:
                root.actionChangeRequested(RegionSelector.SnipAction.Record);
                break;
            case Qt.Key_F:
                // Select fullscreen (Shift+F = edit in swappy)
                // Only capture if mouse is on this monitor
                if (!root.cursorOnThisMonitor)
                    break;
                root.snipping = true;
                root.regionX = 0;
                root.regionY = 0;
                root.regionWidth = root.width;
                root.regionHeight = root.height;
                root.editMode = (event.modifiers & Qt.ShiftModifier);
                root.lensMode = false;
                root.ocrMode = false;
                root.ocrTranslate = false;
                root.snip();
                break;
            case Qt.Key_C:
                // Shrink selection to content bounds
                if (root.adjusting && root.cursorOnThisMonitor) {
                    root.shrinkToContent();
                }
                break;
            case Qt.Key_L:
                // Send to Google Lens for visual search
                if (root.adjusting && root.regionWidth > 0 && root.regionHeight > 0 && root.cursorOnThisMonitor) {
                    root.snipping = true;
                    root.editMode = false;
                    root.lensMode = true;
                    root.ocrMode = false;
                    root.ocrTranslate = false;
                    root.snip();
                }
                break;
            case Qt.Key_O:
                // Extract text via Tesseract OCR
                // O = English, Shift+O = all languages, Ctrl+O = all languages + Kagi Translate
                if (root.adjusting && root.regionWidth > 0 && root.regionHeight > 0 && root.cursorOnThisMonitor) {
                    root.snipping = true;
                    root.editMode = false;
                    root.lensMode = false;
                    root.ocrMode = true;
                    root.ocrTranslate = (event.modifiers & Qt.ControlModifier);
                    root.ocrAllLangs = (event.modifiers & Qt.ShiftModifier) || root.ocrTranslate;
                    root.snip();
                }
                break;
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true

            // Once Wayland starts delivering hover events, keep the shared
            // flag in sync with the real hover state.
            onContainsMouseChanged: root.cursorOnThisMonitor = containsMouse

            Component.onCompleted: root._probeCursorMonitor()
            Connections {
                target: root
                function onPreparationDoneChanged() {
                    root._probeCursorMonitor();
                }
            }

            onPressed: mouse => {
                if (root.adjusting) {
                    // Check if clicking on a handle or inside selection
                    const handle = root.getHandleAt(mouse.x, mouse.y);
                    if (handle) {
                        root.adjustHandle = handle;
                        root.adjustStartX = mouse.x;
                        root.adjustStartY = mouse.y;
                        root.adjustStartRegionX = root.regionX;
                        root.adjustStartRegionY = root.regionY;
                        root.adjustStartRegionW = root.regionWidth;
                        root.adjustStartRegionH = root.regionHeight;
                    } else {
                        // Clicked outside - start new selection
                        root.adjusting = false;
                        root.regionWidth = 0;
                        root.regionHeight = 0;
                        root.dragStartX = mouse.x;
                        root.dragStartY = mouse.y;
                        root.draggingX = mouse.x;
                        root.draggingY = mouse.y;
                        root.dragging = true;
                    }
                } else {
                    root.dragStartX = mouse.x;
                    root.dragStartY = mouse.y;
                    root.draggingX = mouse.x;
                    root.draggingY = mouse.y;
                    root.dragging = true;
                }
            }

            onReleased: mouse => {
                if (root.adjustHandle) {
                    root.adjustHandle = "";
                    return;
                }

                root.dragging = false;

                // If no drag, use targeted window region or click to snip
                if (root.draggingX === root.dragStartX && root.draggingY === root.dragStartY) {
                    if (root.hasTargetedRegion) {
                        root.setRegionToTargeted();
                        root.adjusting = true;
                    }
                    return;
                }

                // Compute final region from drag
                root.regionX = Math.min(root.dragStartX, root.draggingX);
                root.regionY = Math.min(root.dragStartY, root.draggingY);
                root.regionWidth = Math.abs(root.draggingX - root.dragStartX);
                root.regionHeight = Math.abs(root.draggingY - root.dragStartY);

                // Enter adjustment mode if we have a selection
                if (root.regionWidth > 5 && root.regionHeight > 5) {
                    root.adjusting = true;
                }
            }

            onPositionChanged: mouse => {
                if (root.adjustHandle) {
                    root.handleAdjustment(mouse.x, mouse.y);
                    return;
                }

                root.updateTargetedRegion(mouse.x, mouse.y);

                if (root.dragging) {
                    root.draggingX = mouse.x;
                    root.draggingY = mouse.y;
                    // Update region during drag
                    root.regionX = Math.min(root.dragStartX, root.draggingX);
                    root.regionY = Math.min(root.dragStartY, root.draggingY);
                    root.regionWidth = Math.abs(root.draggingX - root.dragStartX);
                    root.regionHeight = Math.abs(root.draggingY - root.dragStartY);
                }
            }

            // Selection overlay (during drag or adjusting)
            SelectionOverlay {
                anchors.fill: parent
                regionX: root.regionX
                regionY: root.regionY
                regionWidth: root.regionWidth
                regionHeight: root.regionHeight
                mouseX: mouseArea.mouseX
                mouseY: mouseArea.mouseY
                visible: root.regionWidth > 2 && root.regionHeight > 2 && !root.snipping
            }

            // Corner bracket handles (only in adjusting mode)
            Item {
                visible: root.adjusting && root.regionWidth > 0 && !root.snipping
                z: 10

                readonly property int bracketLength: 20
                readonly property int bracketThickness: 5
                readonly property color bracketColor: Theme.textColor

                // L-shaped corner brackets
                Repeater {
                    model: [
                        // nw: horizontal goes right, vertical goes down
                        {
                            x: root.regionX,
                            y: root.regionY,
                            hDir: 1,
                            vDir: 1
                        },
                        // ne: horizontal goes left, vertical goes down
                        {
                            x: root.regionX + root.regionWidth,
                            y: root.regionY,
                            hDir: -1,
                            vDir: 1
                        },
                        // sw: horizontal goes right, vertical goes up
                        {
                            x: root.regionX,
                            y: root.regionY + root.regionHeight,
                            hDir: 1,
                            vDir: -1
                        },
                        // se: horizontal goes left, vertical goes up
                        {
                            x: root.regionX + root.regionWidth,
                            y: root.regionY + root.regionHeight,
                            hDir: -1,
                            vDir: -1
                        }
                    ]
                    Item {
                        required property var modelData
                        // Horizontal arm of L
                        Rectangle {
                            x: modelData.hDir > 0 ? modelData.x : modelData.x - parent.parent.bracketLength
                            y: modelData.vDir > 0 ? modelData.y : modelData.y - parent.parent.bracketThickness
                            width: parent.parent.bracketLength
                            height: parent.parent.bracketThickness
                            color: parent.parent.bracketColor
                        }
                        // Vertical arm of L
                        Rectangle {
                            x: modelData.hDir > 0 ? modelData.x : modelData.x - parent.parent.bracketThickness
                            y: modelData.vDir > 0 ? modelData.y : modelData.y - parent.parent.bracketLength
                            width: parent.parent.bracketThickness
                            height: parent.parent.bracketLength
                            color: parent.parent.bracketColor
                        }
                    }
                }
            }

            // Window region highlights (hidden during adjusting or dragging)
            Repeater {
                model: root.windowRegions
                delegate: WindowRegion {
                    required property var modelData
                    required property int index
                    readonly property bool isDraggingRegion: root.regionWidth > 5 || root.regionHeight > 5
                    readonly property bool isTiled: !modelData.floating
                    clientDimensions: modelData
                    targeted: !isDraggingRegion && !root.snipping && !root.adjusting && root.targetedRegionX === modelData.at[0] && root.targetedRegionY === modelData.at[1]
                    opacity: (isDraggingRegion || root.snipping || root.adjusting) ? 0 : 1.0
                    // Compute cutouts: for tiled windows, cut out all floating windows
                    // For floating windows, cut out smaller floating windows (higher priority)
                    cutouts: {
                        const tx = modelData.at[0];
                        const ty = modelData.at[1];
                        const tw = modelData.size[0];
                        const th = modelData.size[1];
                        const myArea = tw * th;

                        // Windows to cut out: all floating windows that should appear "above" this one
                        const windowsToCut = isTiled ? root.floatingWindows  // Tiled: cut out all floating
                        : root.floatingWindows.filter(fw => {
                            // Floating: cut out smaller floating windows (they have priority)
                            const fwArea = fw.size[0] * fw.size[1];
                            return fwArea < myArea;
                        });

                        return windowsToCut.map(fw => {
                            const fx = fw.at[0];
                            const fy = fw.at[1];
                            const fww = fw.size[0];
                            const fwh = fw.size[1];
                            // Compute intersection
                            const ix = Math.max(tx, fx);
                            const iy = Math.max(ty, fy);
                            const ix2 = Math.min(tx + tw, fx + fww);
                            const iy2 = Math.min(ty + th, fy + fwh);
                            if (ix < ix2 && iy < iy2) {
                                // Convert to local coordinates
                                return {
                                    x: ix - tx,
                                    y: iy - ty,
                                    width: ix2 - ix,
                                    height: iy2 - iy
                                };
                            }
                            return null;
                        }).filter(c => c !== null);
                    }
                }
            }

            // Bottom toolbar
            Toolbar {
                id: toolbar
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 20
                }
                action: root.action
                adjusting: root.adjusting
                onDismiss: root.dismiss()
                onCropRequested: root.shrinkToContent()
                onLensRequested: {
                    root.snipping = true;
                    root.editMode = false;
                    root.lensMode = true;
                    root.ocrMode = false;
                    root.ocrTranslate = false;
                    root.snip();
                }
                onOcrRequested: {
                    root.snipping = true;
                    root.editMode = false;
                    root.lensMode = false;
                    root.ocrMode = true;
                    root.ocrAllLangs = false;
                    root.ocrTranslate = false;
                    root.snip();
                }
                onOcrAllRequested: {
                    root.snipping = true;
                    root.editMode = false;
                    root.lensMode = false;
                    root.ocrMode = true;
                    root.ocrAllLangs = true;
                    root.ocrTranslate = false;
                    root.snip();
                }
                onTranslateRequested: {
                    root.snipping = true;
                    root.editMode = false;
                    root.lensMode = false;
                    root.ocrMode = true;
                    root.ocrAllLangs = true;
                    root.ocrTranslate = true;
                    root.snip();
                }
                onActionRequested: newAction => {
                    if (newAction === -1) {
                        // Fullscreen
                        root.snipping = true;
                        root.regionX = 0;
                        root.regionY = 0;
                        root.regionWidth = root.width;
                        root.regionHeight = root.height;
                        root.editMode = false;
                        root.lensMode = false;
                        root.ocrMode = false;
                        root.ocrTranslate = false;
                        root.snip();
                    } else {
                        root.action = newAction;
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        root._tlog("Component.onCompleted");
        Logger.debug(`RegionSelector: Window initialized on ${screen.name}`);
    }
}
