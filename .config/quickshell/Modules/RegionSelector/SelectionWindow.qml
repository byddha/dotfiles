import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../Config"
import "../../Services"
import "../../Utils"
import "../../Components"

PanelWindow {
    id: root

    property int action: RegionSelector.SnipAction.Copy
    property bool recordAudio: false
    property bool recordMic: false
    signal dismiss
    signal actionChangeRequested(int newAction)
    signal audioToggleRequested
    signal micToggleRequested

    visible: true
    color: "transparent"
    WlrLayershell.namespace: "bidshell:regionselector"
    WlrLayershell.layer: WlrLayer.Overlay
    // Only the focused monitor's window takes the keyboard (as in DankMaterialShell's overview);
    // with Exclusive on every window, Hyprland gave keys to a random one and Space/F were ignored.
    WlrLayershell.keyboardFocus: Compositor.focusedMonitorName === screen?.name ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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
    // What snip() does with the grabbed region: "copy" (clipboard), "edit" (Swappy),
    // "save" (~/Pictures/Screenshots), "lens" (Google Lens) or "ocr" (scripts/ocr, set up by `qs ipc call setup ocr`)
    property string snipMode: "copy"
    property bool ocrTranslate: false // When true, open OCR result in Kagi Translate
    property string adjustHandle: ""  // Which handle is being dragged: "", "move", "nw", "ne", "sw", "se", "n", "s", "e", "w"
    property real adjustStartX: 0
    property real adjustStartY: 0
    property real adjustStartRegionX: 0
    property real adjustStartRegionY: 0
    property real adjustStartRegionW: 0
    property real adjustStartRegionH: 0

    // Window regions on this workspace, sorted for proper z-order (floating above tiled)
    readonly property var windowRegions: {
        const workspaceWindows = Compositor.windowList.filter(w => w.workspace.id === root.effectiveWorkspaceId);
        const toRegion = w => ({
                    at: [w.at[0] - root.monitorOffsetX, w.at[1] - root.monitorOffsetY],
                    size: w.size,
                    class: w.class,
                    title: w.title,
                    floating: w.floating
                });

        // If any window is fullscreen or maximized, only show that window (others are occluded)
        // fullscreen: 1 = real fullscreen, 2 = maximized
        const fullscreenWindow = workspaceWindows.find(w => w.fullscreen > 0);
        if (fullscreenWindow)
            return [toRegion(fullscreenWindow)];

        // Floating windows first (higher z-order), and among them smaller ones first
        // (easier to target, likely on top)
        const area = w => w.size[0] * w.size[1];
        return workspaceWindows.sort((a, b) => (!!b.floating - !!a.floating) || (a.floating ? area(a) - area(b) : 0)).map(toRegion);
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
    // starts out false until the user wiggles the mouse).
    property bool cursorOnThisMonitor: false
    // False (then undefined) once destroyed: `root` itself stays truthy in a late callback, its functions do not
    property bool alive: true
    Component.onDestruction: alive = false

    function _probeCursorMonitor() {
        if (!root.visible || !root.preparationDone)
            return;
        Compositor.getCursorPosition((globalX, globalY) => {
            // The reply is async; the window may be gone by then.
            if (!root?.alive)
                return;
            const localX = globalX - root.monitorOffsetX;
            const localY = globalY - root.monitorOffsetY;
            root.cursorOnThisMonitor = localX >= 0 && localX < root.width && localY >= 0 && localY < root.height;
            root.updateTargetedRegion(localX, localY);
        });
    }

    // Ensure screenshot temp directory exists (saveToFile won't mkdir)
    Process {
        id: mkdirProc
        running: true
        command: ["mkdir", "-p", root.screenshotDir]
    }

    // UI is interactive as soon as the screencopy buffer arrives (~15ms).
    // We do NOT save a full-screen PNG at startup — encoding a 3440x1440 PNG
    // takes >1s and the user never needs the full file, only the crop they
    // select. Instead, snip() and shrinkToContent() each grab a cropped region
    // on demand via the `regionCrop` ShaderEffectSource below.
    Connections {
        target: screencopyView
        function onHasContentChanged() {
            if (!screencopyView.hasContent || root.preparationDone)
                return;
            root.preparationDone = true;
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

        // grabToImage() renders the item at the window's device pixel ratio (the monitor scale), so the item
        // gets the logical size of the rounded native size: the image comes out exactly nativeW x nativeH.
        // (A native item size would be scaled twice; a fractional logical size would be truncated.)
        readonly property int nativeW: Math.max(1, Math.round(grabW * grabScale))
        readonly property int nativeH: Math.max(1, Math.round(grabH * grabScale))
        sourceRect: Qt.rect(grabX, grabY, grabW, grabH)
        width: nativeW / grabScale
        height: nativeH / grabScale
        textureSize: Qt.size(nativeW, nativeH)
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
        // Snap the edges to the monitor's pixel grid: the pointer gives sub-pixel positions, and a region that
        // starts between pixels is sampled across two of them, which blurs every sharp edge in the image.
        const scale = root.monitorScale;
        const left = Math.round(rx * scale);
        const top = Math.round(ry * scale);
        const right = Math.round((rx + rw) * scale);
        const bottom = Math.round((ry + rh) * scale);
        regionCrop.grabScale = scale;
        regionCrop.grabX = left / scale;
        regionCrop.grabY = top / scale;
        regionCrop.grabW = Math.max(1, right - left) / scale;
        regionCrop.grabH = Math.max(1, bottom - top) / scale;
        regionCrop.scheduleUpdate();
        // One tick so ShaderEffectSource re-captures with the new sourceRect
        Qt.callLater(() => {
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
                onDone(true);
            });
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

    readonly property bool canSnip: adjusting && regionWidth > 0 && regionHeight > 0 && cursorOnThisMonitor
    readonly property bool fullscreenSelected: adjusting && regionX === 0 && regionY === 0 && regionWidth === width && regionHeight === height

    function clearSelection() {
        root.adjusting = false;
        root.regionWidth = 0;
        root.regionHeight = 0;
    }

    // The whole monitor becomes the selection, so every output and the record options work on it,
    // and the handles can still trim it; again clears it
    function toggleFullscreen() {
        if (root.fullscreenSelected) {
            root.clearSelection();
            return;
        }
        root.regionX = 0;
        root.regionY = 0;
        root.regionWidth = root.width;
        root.regionHeight = root.height;
        root.adjusting = true;
    }

    function snipAs(mode, translate = false) {
        root.snipping = true;
        root.snipMode = mode;
        root.ocrTranslate = translate;
        root.snip();
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

        // Record mode: the recorder captures live, no file grab needed. Lens, OCR, Edit and Save
        // still take a screenshot of the region.
        if (root.action === RegionSelector.SnipAction.Record && root.snipMode === "copy") {
            Recording.start(Math.round(root.regionX + root.monitorOffsetX), Math.round(root.regionY + root.monitorOffsetY), Math.round(root.regionWidth), Math.round(root.regionHeight), root.recordAudio, root.recordMic);
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
            if (root.snipMode === "save") {
                cmd = `mkdir -p ~/Pictures/Screenshots && cp '${f}' ~/Pictures/Screenshots/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png && ${cleanup}`;
            } else if (root.snipMode === "lens") {
                cmd = `imageLink=$(curl -sF files[]=@'${f}' 'https://uguu.se/upload' | jq -r '.files[0].url') && xdg-open "https://lens.google.com/uploadbyurl?url=\${imageLink}" && ${cleanup}`;
            } else if (root.snipMode === "ocr") {
                // Without the venv (not set up yet, or broken by a Python upgrade) it says what to run
                const script = Qt.resolvedUrl("../../scripts/ocr/ocr.py").toString().replace("file://", "");
                const read = `text=$("\${XDG_DATA_HOME:-$HOME/.local/share}/bidshell/ocr/venv/bin/python" '${script}' '${f}') || { notify-send -a OCR "OCR is not set up" "Run: qs ipc call setup ocr"; ${cleanup}; exit; }`;
                const copy = `printf '%s' "$text" | wl-copy`;
                cmd = root.ocrTranslate ? `${read}; ${copy} && xdg-open "https://translate.kagi.com/?from=auto&to=&text=$(printf '%s' "$text" | jq -sRr @uri)" && ${cleanup}` : `${read}; ${copy} && ${cleanup}`;
            } else if (root.snipMode === "edit") {
                cmd = `swappy -f '${f}' && ${cleanup}`;
            } else {
                cmd = `wl-copy --type image/png < '${f}' && ${cleanup}`;
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
    Spinner {
        anchors.centerIn: parent
        visible: root.snipping
        size: 160
        color: Theme.primary
        z: 10
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
                if (toolbar.ocrMenuOpen)
                    toolbar.ocrMenuOpen = false;
                else
                    root.dismiss();
                break;
            case Qt.Key_Space:
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (root.canSnip)
                    root.snipAs("copy");
                break;
            case Qt.Key_E:
                if (root.canSnip)
                    root.snipAs("edit");
                break;
            case Qt.Key_S:
                if (event.modifiers & Qt.ControlModifier) {
                    if (root.canSnip)
                        root.snipAs("save");
                } else {
                    // Plain S: Switch to Screenshot mode
                    root.actionChangeRequested(RegionSelector.SnipAction.Copy);
                }
                break;
            case Qt.Key_R:
                root.actionChangeRequested(RegionSelector.SnipAction.Record);
                break;
            case Qt.Key_A:
                if (root.action === RegionSelector.SnipAction.Record)
                    root.audioToggleRequested();
                break;
            case Qt.Key_M:
                if (root.action === RegionSelector.SnipAction.Record)
                    root.micToggleRequested();
                break;
            case Qt.Key_F:
                if (root.cursorOnThisMonitor)
                    root.toggleFullscreen();
                break;
            case Qt.Key_C:
                // Shrink selection to content bounds
                if (root.adjusting && root.cursorOnThisMonitor) {
                    root.shrinkToContent();
                }
                break;
            case Qt.Key_L:
                if (root.canSnip)
                    root.snipAs("lens");
                break;
            case Qt.Key_O:
                // O = copy the text, Ctrl+O = also open it in Kagi Translate
                if (root.canSnip && !(event.modifiers & Qt.ShiftModifier))
                    root.snipAs("ocr", !!(event.modifiers & Qt.ControlModifier));
                break;
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true

            // A spurious leave arrives while the per-monitor surfaces map, with the cursor
            // still here; trusting it left Space/F dead until the mouse moved. Re-probe instead.
            onContainsMouseChanged: {
                if (containsMouse)
                    root.cursorOnThisMonitor = true;
                else
                    root._probeCursorMonitor();
            }

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
                        root.clearSelection();
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
                monitorScale: root.monitorScale
                showHandles: root.adjusting
                visible: root.regionWidth > 2 && root.regionHeight > 2 && !root.snipping
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

            // Closes the OCR menu on a press anywhere else, without starting a selection
            MouseArea {
                anchors.fill: parent
                visible: toolbar.ocrMenuOpen
                z: 19
                onPressed: toolbar.ocrMenuOpen = false
            }

            // Bottom toolbar, snapped to whole physical pixels so it stays sharp on scaled monitors
            Toolbar {
                id: toolbar
                z: 20
                x: Math.round((parent.width - width) / 2 * root.monitorScale) / root.monitorScale
                y: Math.round((parent.height - height - 60) * root.monitorScale) / root.monitorScale
                width: implicitWidth
                height: implicitHeight
                action: root.action
                adjusting: root.adjusting
                fullscreen: root.fullscreenSelected
                recordAudio: root.recordAudio
                recordMic: root.recordMic
                onAudioToggled: root.audioToggleRequested()
                onMicToggled: root.micToggleRequested()
                onDismiss: root.dismiss()
                onFullscreenRequested: root.toggleFullscreen()
                onCropRequested: root.shrinkToContent()
                onSnipRequested: (mode, translate) => root.snipAs(mode, translate)
                onActionRequested: newAction => root.actionChangeRequested(newAction)
            }
        }
    }
}
