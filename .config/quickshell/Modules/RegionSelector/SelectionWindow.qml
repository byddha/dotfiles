import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../../Config"
import "../../Services"
import "../../Services/Hyprland"
import "../../Utils"

PanelWindow {
    id: root

    property int action: RegionSelector.SnipAction.Copy
    signal dismiss()
    signal actionChangeRequested(int newAction)

    visible: false
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

    // Monitor info
    readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property real monitorScale: hyprlandMonitor?.scale ?? 1
    readonly property real monitorOffsetX: hyprlandMonitor?.x ?? 0
    readonly property real monitorOffsetY: hyprlandMonitor?.y ?? 0
    property int activeWorkspaceId: hyprlandMonitor?.activeWorkspace?.id ?? 0

    // Screenshot paths
    readonly property string screenshotDir: "/tmp/bidshell-screenshots"
    readonly property string screenshotPath: `${screenshotDir}/region-${screen.name}.png`

    // Selection state
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property bool dragging: false
    property int mouseButton: Qt.LeftButton

    // Computed region
    property real regionX: Math.min(dragStartX, draggingX)
    property real regionY: Math.min(dragStartY, draggingY)
    property real regionWidth: Math.abs(draggingX - dragStartX)
    property real regionHeight: Math.abs(draggingY - dragStartY)

    // Window regions from HyprlandData (reversed so topmost windows are checked first)
    readonly property var windowRegions: HyprlandData.windowList
        .filter(w => w.workspace.id === root.activeWorkspaceId)
        .map(w => ({
            at: [w.at[0] - root.monitorOffsetX, w.at[1] - root.monitorOffsetY],
            size: w.size,
            class: w.class,
            title: w.title
        }))
        .reverse()

    // Targeted window region (for click-to-select)
    property real targetedRegionX: -1
    property real targetedRegionY: -1
    property real targetedRegionWidth: 0
    property real targetedRegionHeight: 0
    property bool hasTargetedRegion: targetedRegionX >= 0 && targetedRegionY >= 0

    // Preparation state
    property bool preparationDone: false
    property bool snipping: false

    // Screenshot capture process
    Process {
        id: screenshotProc
        running: true
        command: ["bash", "-c", `mkdir -p '${root.screenshotDir}' && grim -o '${root.screen.name}' '${root.screenshotPath}'`]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.preparationDone = true;
                root.visible = true;
                Logger.debug("RegionSelector: Screenshot captured for", root.screen.name);
            } else {
                Logger.error("RegionSelector: Screenshot capture failed");
                root.dismiss();
            }
        }
    }

    // Snip process
    Process {
        id: snipProc
    }

    // Copy feedback animation - shrink to corner
    property real thumbMaxSize: 200
    property real thumbTargetW: 0
    property real thumbTargetH: 0

    SequentialAnimation {
        id: feedbackAnimation

        // Store initial values and calculate aspect-ratio-correct thumbnail size
        ScriptAction {
            script: {
                // Capture current region (break bindings by setting directly)
                feedbackOverlay.x = root.regionX;
                feedbackOverlay.y = root.regionY;
                feedbackOverlay.width = root.regionWidth;
                feedbackOverlay.height = root.regionHeight;
                feedbackOverlay.startX = root.regionX;
                feedbackOverlay.startY = root.regionY;
                feedbackOverlay.startWidth = root.regionWidth;
                feedbackOverlay.startHeight = root.regionHeight;
                feedbackOverlay.opacity = 1;

                // Calculate thumbnail size preserving aspect ratio
                const aspect = root.regionWidth / root.regionHeight;
                if (aspect > 1) {
                    // Wider than tall
                    root.thumbTargetW = root.thumbMaxSize;
                    root.thumbTargetH = root.thumbMaxSize / aspect;
                } else {
                    // Taller than wide
                    root.thumbTargetH = root.thumbMaxSize;
                    root.thumbTargetW = root.thumbMaxSize * aspect;
                }
            }
        }

        // Brief pause to show the capture
        PauseAnimation { duration: 80 }

        // Shrink and move to corner
        ParallelAnimation {
            NumberAnimation {
                target: feedbackOverlay
                property: "x"
                to: 40
                duration: 350
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: feedbackOverlay
                property: "y"
                to: 80
                duration: 350
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: feedbackOverlay
                property: "width"
                to: root.thumbTargetW
                duration: 350
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: feedbackOverlay
                property: "height"
                to: root.thumbTargetH
                duration: 350
                easing.type: Easing.OutCubic
            }
        }

        // Pause at corner to let it settle
        PauseAnimation { duration: 150 }

        // Fade out
        NumberAnimation {
            target: feedbackOverlay
            property: "opacity"
            to: 0
            duration: 100
            easing.type: Easing.InQuad
        }

        ScriptAction {
            script: root.dismiss()
        }
    }

    function updateTargetedRegion(x, y) {
        const clickedWindow = root.windowRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] &&
                   region.at[1] <= y && y <= region.at[1] + region.size[1];
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

    function snip() {
        if (root.regionWidth <= 0 || root.regionHeight <= 0) {
            // No region - try to find window at click position
            root.updateTargetedRegion(root.dragStartX, root.dragStartY);
            if (root.hasTargetedRegion) {
                root.setRegionToTargeted();
            } else {
                // No window found, dismiss
                root.dismiss();
                return;
            }
        }

        const effectiveAction = root.action;

        // Scale region for actual screenshot coordinates
        const rx = Math.round(root.regionX * root.monitorScale);
        const ry = Math.round(root.regionY * root.monitorScale);
        const rw = Math.round(root.regionWidth * root.monitorScale);
        const rh = Math.round(root.regionHeight * root.monitorScale);

        const cropToStdout = `magick '${root.screenshotPath}' -crop ${rw}x${rh}+${rx}+${ry} +repage -`;
        const cleanup = `rm '${root.screenshotPath}'`;

        // Region in slurp format for wf-recorder
        const slurpRegion = `${Math.round(root.regionX + root.monitorOffsetX)},${Math.round(root.regionY + root.monitorOffsetY)} ${rw}x${rh}`;

        // Right-click opens in swappy regardless of mode
        if (root.mouseButton === Qt.RightButton && effectiveAction === RegionSelector.SnipAction.Copy) {
            snipProc.command = ["bash", "-c", `${cropToStdout} | swappy -f - && ${cleanup}`];
            Logger.info("RegionSelector: Opening region in swappy");
        } else {
            switch (effectiveAction) {
                case RegionSelector.SnipAction.Copy:
                    snipProc.command = ["bash", "-c", `${cropToStdout} | wl-copy && ${cleanup}`];
                    Logger.info("RegionSelector: Copying region to clipboard");
                    break;
                case RegionSelector.SnipAction.Record:
                    const recordCmd = `${cleanup} && mkdir -p ~/Videos/Screencasts && wf-recorder -g '${slurpRegion}' -c h264_vaapi -f ~/Videos/Screencasts/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4`;
                    snipProc.command = ["bash", "-c", recordCmd];
                    Logger.info("RegionSelector: Starting recording:", recordCmd);
                    break;
            }
        }

        snipProc.startDetached();

        // Show feedback only for Copy mode (not Record or edit via right-click)
        if (effectiveAction === RegionSelector.SnipAction.Copy && root.mouseButton !== Qt.RightButton) {
            feedbackAnimation.start();
        } else {
            root.dismiss();
        }
    }

    // Frozen screen capture
    ScreencopyView {
        id: screencopyView
        anchors.fill: parent
        live: false
        captureSource: root.screen

        focus: root.visible
        Keys.onPressed: (event) => {
            switch (event.key) {
                case Qt.Key_Escape:
                    root.dismiss();
                    break;
                case Qt.Key_S:
                    root.actionChangeRequested(RegionSelector.SnipAction.Copy);
                    break;
                case Qt.Key_R:
                    root.actionChangeRequested(RegionSelector.SnipAction.Record);
                    break;
                case Qt.Key_F:
                    // Select fullscreen (Shift+F = edit in swappy)
                    // Only capture if mouse is on this monitor
                    if (!mouseArea.containsMouse) break;
                    root.snipping = true;
                    root.regionX = 0;
                    root.regionY = 0;
                    root.regionWidth = root.width;
                    root.regionHeight = root.height;
                    if (event.modifiers & Qt.ShiftModifier) {
                        root.mouseButton = Qt.RightButton;  // Triggers edit mode
                    }
                    root.snip();
                    break;
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true

            // Get initial cursor position from Hyprland (Qt's mouseX/Y is stale on Wayland)
            Process {
                id: cursorPosProc
                command: ["hyprctl", "cursorpos"]
                running: root.visible && root.preparationDone
                stdout: SplitParser {
                    onRead: data => {
                        const parts = data.trim().split(", ");
                        if (parts.length === 2) {
                            const globalX = parseInt(parts[0]);
                            const globalY = parseInt(parts[1]);
                            // Convert to monitor-local coordinates
                            const localX = globalX - root.monitorOffsetX;
                            const localY = globalY - root.monitorOffsetY;
                            root.updateTargetedRegion(localX, localY);
                        }
                    }
                }
            }

            onPressed: (mouse) => {
                root.dragStartX = mouse.x;
                root.dragStartY = mouse.y;
                root.draggingX = mouse.x;
                root.draggingY = mouse.y;
                root.dragging = true;
                root.mouseButton = mouse.button;
            }

            onReleased: (mouse) => {
                root.snipping = true;  // Freeze UI before state changes
                // If no drag, use targeted window region
                if (root.draggingX === root.dragStartX &&
                    root.draggingY === root.dragStartY) {
                    if (root.hasTargetedRegion) {
                        root.setRegionToTargeted();
                    }
                }
                root.snip();
            }

            onPositionChanged: (mouse) => {
                root.updateTargetedRegion(mouse.x, mouse.y);
                if (!root.dragging) return;
                root.draggingX = mouse.x;
                root.draggingY = mouse.y;
            }

            // Selection overlay (only during active drag, not when snipping a window)
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

            // Window region highlights
            Repeater {
                model: root.windowRegions
                delegate: WindowRegion {
                    required property var modelData
                    required property int index
                    readonly property bool isDraggingRegion: root.regionWidth > 5 || root.regionHeight > 5
                    clientDimensions: modelData
                    targeted: !isDraggingRegion && !root.snipping &&
                        root.targetedRegionX === modelData.at[0] &&
                        root.targetedRegionY === modelData.at[1]
                    opacity: (isDraggingRegion || root.snipping) ? 0 : 1.0
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
                onDismiss: root.dismiss()
                onActionRequested: (newAction) => {
                    if (newAction === -1) {
                        // Fullscreen
                        root.snipping = true;
                        root.regionX = 0;
                        root.regionY = 0;
                        root.regionWidth = root.width;
                        root.regionHeight = root.height;
                        root.snip();
                    } else {
                        root.action = newAction;
                    }
                }
            }

            // Shrink-to-corner feedback - captures actual content
            Item {
                id: feedbackOverlay
                property real startX: 0
                property real startY: 0
                property real startWidth: 0
                property real startHeight: 0

                // Position set by animation, not bound to regionX/Y to avoid interference
                x: 0
                y: 0
                width: 0
                height: 0
                opacity: 0
                visible: opacity > 0

                // Captured region content
                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: screencopyView
                    sourceRect: Qt.rect(feedbackOverlay.startX, feedbackOverlay.startY,
                                        feedbackOverlay.startWidth, feedbackOverlay.startHeight)
                    live: false
                }

                // Border frame
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: Theme.primary
                    border.width: 2
                    radius: 4
                }
            }
        }
    }

    Component.onCompleted: {
        Logger.debug(`RegionSelector: Window initialized on ${screen.name}`);
    }
}
