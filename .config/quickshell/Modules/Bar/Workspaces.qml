import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Config"
import "../../Services"
import "../../Utils"
import "../Common"

/**
 * Workspaces - Multi-icon workspace indicator
 *
 * Displays workspace buttons with all app icons and instance counts.
 * Workspace buttons grow dynamically based on number of apps.
 */
Item {
    id: root

    // Workspace range configuration (set from Bar.qml based on monitor)
    property int startWorkspace: 1
    property int endWorkspace: 5

    // Configuration
    readonly property int workspacesShown: endWorkspace - startWorkspace + 1
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    // Workspace state (initialized with false values to avoid undefined access before updateWorkspaceOccupied runs)
    property list<bool> workspaceOccupied: Array(workspacesShown).fill(false)
    // Index within this group (-1 if active workspace is outside our range)
    property int workspaceIndexInGroup: {
        const activeId = monitor?.activeWorkspace?.id ?? 1;
        if (activeId >= startWorkspace && activeId <= endWorkspace) {
            return activeId - startWorkspace;
        }
        return -1;  // Active workspace is outside our range
    }

    // Sizing
    property int baseWorkspaceWidth: BarStyle.buttonSize
    property real activeWorkspaceMargin: 2
    property real iconSize: 26
    property real iconSpacing: 4

    // Update workspace occupation status
    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({
            length: root.workspacesShown
        }, (_, i) => {
            const wsId = root.startWorkspace + i;
            return Hyprland.workspaces.values.some(ws => ws.id === wsId);
        });
    }

    // Calculate workspace positions for animated border
    property var workspacePositions: []
    property real activeWorkspaceX: 0
    property real activeWorkspaceWidth: 0

    function updateActiveWorkspacePosition() {
        const activeId = monitor?.activeWorkspace?.id ?? startWorkspace;
        // If active workspace is outside our range, hide the indicator
        if (activeId < startWorkspace || activeId > endWorkspace) {
            activeWorkspaceWidth = 0;
            return;
        }

        let xPos = 0;
        for (let i = 0; i < workspacesShown; i++) {
            const wsId = startWorkspace + i;
            if (wsId === activeId) {
                activeWorkspaceX = xPos;
                const apps = HyprlandData.getWorkspaceApps(wsId);
                const appCount = apps.length;
                activeWorkspaceWidth = (iconSize * Math.max(1, appCount)) + (iconSpacing * Math.max(0, appCount - 1)) + 8;
                break;
            }
            const apps = HyprlandData.getWorkspaceApps(wsId);
            const appCount = apps.length;
            const width = (iconSize * Math.max(1, appCount)) + (iconSpacing * Math.max(0, appCount - 1)) + 8;
            xPos += width;
        }
    }

    // Initialize and track workspace changes
    Component.onCompleted: {
        updateWorkspaceOccupied();
        updateActiveWorkspacePosition();
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            updateWorkspaceOccupied();
        }
    }

    Connections {
        target: HyprlandData
        function onWindowListChanged() {
            updateActiveWorkspacePosition();
        }
    }

    onWorkspaceIndexInGroupChanged: updateActiveWorkspacePosition()

    implicitWidth: workspaceBackground.width
    implicitHeight: BarStyle.barHeight

    // Find next occupied workspace in a direction (1 = forward, -1 = backward)
    function findNextOccupied(currentId, direction) {
        for (let i = 1; i <= workspacesShown; i++) {
            let nextId = currentId + (direction * i);
            if (nextId > endWorkspace)
                nextId = startWorkspace + (nextId - endWorkspace - 1);
            else if (nextId < startWorkspace)
                nextId = endWorkspace - (startWorkspace - nextId - 1);

            const index = nextId - startWorkspace;
            if (workspaceOccupied[index])
                return nextId;
        }
        // No occupied workspace found, return next in sequence
        let fallback = currentId + direction;
        if (fallback > endWorkspace)
            fallback = startWorkspace;
        else if (fallback < startWorkspace)
            fallback = endWorkspace;
        return fallback;
    }

    // Scroll to switch workspaces (cycles within configured range, skipping empty)
    WheelHandler {
        onWheel: event => {
            const currentId = monitor?.activeWorkspace?.id ?? startWorkspace;
            let nextId;

            if (event.angleDelta.y > 0) {
                // Scroll up = next occupied workspace
                nextId = findNextOccupied(currentId, 1);
            } else if (event.angleDelta.y < 0) {
                // Scroll down = previous occupied workspace
                nextId = findNextOccupied(currentId, -1);
            } else {
                return;
            }

            if (nextId !== currentId) {
                Hyprland.dispatch(`workspace ${nextId}`);
            }
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    // Background for all workspaces
    Rectangle {
        id: workspaceBackground
        width: workspaceRow.width + (BarStyle.spacing * 2)
        height: BarStyle.barHeight
        color: BarStyle.buttonBackground
        radius: BarStyle.buttonRadius

        Behavior on width {
            NumberAnimation {
                duration: Theme.animation.elementMoveFast.duration
                easing.type: Theme.animation.elementMoveFast.type
                easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
            }
        }
    }

    Row {
        id: workspaceRow
        x: BarStyle.spacing
        spacing: 0
        height: BarStyle.barHeight

        Repeater {
            model: root.workspacesShown

            Item {
                id: workspaceContainer
                property int workspaceValue: root.startWorkspace + index
                property var workspaceApps: HyprlandData.getWorkspaceApps(workspaceValue)
                property int appCount: workspaceApps.length
                property bool isActive: (monitor?.activeWorkspace?.id ?? root.startWorkspace) === workspaceValue
                property bool isOccupied: workspaceOccupied[index] ?? false

                // Dynamic width calculation (treat empty as 1 icon for consistent spacing)
                property real contentWidth: (iconSize * Math.max(1, appCount)) + (iconSpacing * Math.max(0, appCount - 1)) + 8

                width: contentWidth
                height: BarStyle.buttonSize

                // Mouse interaction
                MouseArea {
                    id: workspaceMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Hyprland.dispatch(`workspace ${workspaceContainer.workspaceValue}`)
                }

                // Content: workspace number OR app icons
                Item {
                    anchors.fill: parent

                    // Workspace symbol (shown when no apps)
                    Text {
                        visible: workspaceContainer.appCount === 0
                        anchors.centerIn: parent
                        font.family: BarStyle.iconFont
                        font.pixelSize: iconSize / 1.5

                        text: Icons.workspace
                        color: BarStyle.textColor
                    }

                    // App icons (shown when apps exist)
                    Row {
                        visible: workspaceContainer.appCount > 0
                        anchors.centerIn: parent
                        spacing: iconSpacing

                        Repeater {
                            model: workspaceContainer.workspaceApps

                            Item {
                                width: iconSize
                                height: iconSize
                                property var appData: modelData

                                Text {
                                    id: appIcon
                                    anchors.centerIn: parent
                                    font.family: BarStyle.iconFont
                                    font.pixelSize: iconSize
                                    text: AppIcons.getIcon(appData.class, appData.title, appData.xdgTag)
                                    color: workspaceContainer.isActive ? Theme.primary : BarStyle.iconColor
                                }

                                // Count badge (only if count > 1)
                                Rectangle {
                                    visible: appData.count > 1
                                    anchors {
                                        top: parent.top
                                        right: parent.right
                                        topMargin: -1
                                        rightMargin: -1
                                    }
                                    width: Math.max(14, countText.width + 4)
                                    height: 14
                                    radius: 5
                                    color: workspaceContainer.isActive ? Theme.primary : BarStyle.iconColor
                                    border.width: 1
                                    border.color: Theme.colLayer0

                                    Text {
                                        id: countText
                                        anchors.centerIn: parent
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Theme.primaryText
                                        text: appData.count
                                    }
                                }
                            }
                        }
                    }
                }

                // Width animation
                Behavior on contentWidth {
                    NumberAnimation {
                        duration: Theme.animation.elementMoveFast.duration
                        easing.type: Theme.animation.elementMoveFast.type
                        easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                    }
                }

                // Subtle separator
                Rectangle {
                    visible: index < root.workspacesShown - 1
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: parent.height * 0.4
                    color: Theme.textSecondary
                    opacity: 0.5
                }
            }
        }
    }

    // Animated bottom border for active workspace
    Rectangle {
        id: activeBorder
        x: activeWorkspaceX + BarStyle.spacing
        y: BarStyle.barHeight - 3
        width: activeWorkspaceWidth
        height: 3
        color: Theme.primary
        radius: 1.5

        Behavior on x {
            NumberAnimation {
                duration: Theme.animation.elementMoveFast.duration
                easing.type: Theme.animation.elementMoveFast.type
                easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: Theme.animation.elementMoveFast.duration
                easing.type: Theme.animation.elementMoveFast.type
                easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
            }
        }
    }
}
