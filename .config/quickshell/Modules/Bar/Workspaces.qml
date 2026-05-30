import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Utils"

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
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property string screenName: root.QsWindow.window && root.QsWindow.window.screen ? root.QsWindow.window.screen.name : ""
    readonly property var workspaceItems: buildWorkspaceItems()
    readonly property int workspacesShown: workspaceItems.length

    // Active workspace for this monitor (updated via signal)
    property int currentActiveWorkspaceId: Compositor.activeWorkspaceIdForScreen(root.QsWindow.window?.screen)

    // Index within this group (-1 if active workspace is outside our range)
    property int workspaceIndexInGroup: {
        const activeId = currentActiveWorkspaceId;
        for (let i = 0; i < workspaceItems.length; i++) {
            if (workspaceId(workspaceItems[i]) === activeId)
                return i;
        }
        return -1;  // Active workspace is outside this visible group
    }

    // Sizing
    property int baseWorkspaceWidth: BarStyle.buttonSize
    property real activeWorkspaceMargin: 2
    property real iconSize: 26
    property real iconSpacing: 4

    readonly property var currentSpecial: Compositor.isHyprland ? ((Compositor.monitors.find(m => m.name === root.screenName)?.specialWorkspace) ?? null) : null
    readonly property bool specialVisible: (currentSpecial?.id ?? 0) !== 0
    readonly property var specialApps: specialVisible ? Compositor.getWorkspaceApps(currentSpecial.id) : []

    function buildWorkspaceItems() {
        if (Compositor.isNiri) {
            const items = Compositor.workspaces.filter(ws => ws.output === root.screenName);
            return items.sort((a, b) => {
                const aIdx = a.idx !== undefined ? a.idx : 0;
                const bIdx = b.idx !== undefined ? b.idx : 0;
                return aIdx - bIdx;
            });
        }

        const items = [];
        for (let i = root.startWorkspace; i <= root.endWorkspace; i++) {
            items.push({
                id: i
            });
        }
        return items;
    }

    function workspaceId(workspace) {
        return workspace && workspace.id !== undefined ? workspace.id : workspace;
    }

    function workspaceApps(workspace) {
        return Compositor.getWorkspaceApps(workspaceId(workspace));
    }

    function workspaceIsOccupied(workspace) {
        if (Compositor.isNiri)
            return workspaceApps(workspace).length > 0;
        return Compositor.workspaces.some(ws => ws.id === workspaceId(workspace));
    }

    // Calculate workspace positions for animated border
    property var workspacePositions: []
    property real activeWorkspaceX: 0
    property real activeWorkspaceWidth: 0

    function updateActiveWorkspacePosition() {
        const activeId = currentActiveWorkspaceId;
        const activeIndex = workspaceIndexInGroup;
        // If active workspace is outside our visible items, hide the indicator
        if (activeIndex < 0) {
            activeWorkspaceWidth = 0;
            return;
        }

        let xPos = 0;
        for (let i = 0; i < workspaceItems.length; i++) {
            const workspace = workspaceItems[i];
            const wsId = workspaceId(workspace);
            const apps = workspaceApps(workspace);
            const appCount = apps.length;
            const width = (iconSize * Math.max(1, appCount)) + (iconSpacing * Math.max(0, appCount - 1)) + 8;
            if (wsId === activeId) {
                activeWorkspaceX = xPos;
                activeWorkspaceWidth = width;
                break;
            }
            xPos += width;
        }
    }

    // Initialize and track workspace changes
    Component.onCompleted: {
        updateActiveWorkspacePosition();
    }

    Connections {
        target: Compositor

        function onWorkspaceFocusChanged() {
            currentActiveWorkspaceId = Compositor.activeWorkspaceIdForScreen(root.QsWindow.window?.screen);
            updateActiveWorkspacePosition();
        }

        function onWindowDataUpdated() {
            currentActiveWorkspaceId = Compositor.activeWorkspaceIdForScreen(root.QsWindow.window?.screen);
            updateActiveWorkspacePosition();
        }

        function onMonitorDataUpdated() {
            currentActiveWorkspaceId = Compositor.activeWorkspaceIdForScreen(root.QsWindow.window?.screen);
            updateActiveWorkspacePosition();
        }
    }

    onWorkspaceIndexInGroupChanged: updateActiveWorkspacePosition()
    onWorkspaceItemsChanged: updateActiveWorkspacePosition()

    implicitWidth: workspaceBackground.width + (root.specialVisible ? specialPill.width + BarStyle.spacing : 0)
    implicitHeight: BarStyle.barHeight

    // Find next occupied workspace in a direction (1 = forward, -1 = backward)
    function findNextOccupied(currentId, direction) {
        if (workspaceItems.length === 0)
            return currentId;

        const currentIndex = workspaceItems.findIndex(ws => workspaceId(ws) === currentId);
        const startIndex = currentIndex >= 0 ? currentIndex : 0;

        if (Compositor.isNiri) {
            let nextIndex = startIndex + direction;
            if (nextIndex >= workspaceItems.length)
                nextIndex = 0;
            else if (nextIndex < 0)
                nextIndex = workspaceItems.length - 1;
            return workspaceId(workspaceItems[nextIndex]);
        }

        for (let i = 1; i <= workspaceItems.length; i++) {
            let nextIndex = startIndex + (direction * i);
            while (nextIndex >= workspaceItems.length)
                nextIndex -= workspaceItems.length;
            while (nextIndex < 0)
                nextIndex += workspaceItems.length;

            const nextWorkspace = workspaceItems[nextIndex];
            if (workspaceIsOccupied(nextWorkspace))
                return workspaceId(nextWorkspace);
        }

        let fallbackIndex = startIndex + direction;
        if (fallbackIndex >= workspaceItems.length)
            fallbackIndex = 0;
        else if (fallbackIndex < 0)
            fallbackIndex = workspaceItems.length - 1;
        return workspaceId(workspaceItems[fallbackIndex]);
    }

    // Scroll to switch workspaces (cycles within configured range, skipping empty)
    WheelHandler {
        onWheel: event => {
            const currentId = root.currentActiveWorkspaceId;
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
                Compositor.switchWorkspace(nextId);
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
            model: ScriptModel {
                values: root.workspaceItems
            }

            Item {
                id: workspaceContainer
                property var workspaceData: modelData
                property int workspaceValue: root.workspaceId(workspaceData)
                property var workspaceApps: root.workspaceApps(workspaceData)
                property int appCount: workspaceApps.length
                property bool isActive: root.currentActiveWorkspaceId === workspaceValue
                property bool isOccupied: root.workspaceIsOccupied(workspaceData)

                // Dynamic width calculation (treat empty as 1 icon for consistent spacing)
                property real contentWidth: (iconSize * Math.max(1, appCount)) + (iconSpacing * Math.max(0, appCount - 1)) + 8

                width: contentWidth
                height: BarStyle.buttonSize

                // Mouse interaction
                MouseArea {
                    id: workspaceMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Compositor.switchWorkspace(workspaceContainer.workspaceValue)
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
                    visible: index < root.workspaceItems.length - 1
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

    Rectangle {
        id: specialPill
        x: workspaceBackground.width + BarStyle.spacing
        y: 0
        height: BarStyle.barHeight
        width: root.specialVisible ? (specialContent.implicitWidth + BarStyle.spacing * 2) : 0
        color: Theme.primary
        radius: BarStyle.buttonRadius
        opacity: root.specialVisible ? 1.0 : 0.0
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: Theme.animation.elementMoveFast.duration
                easing.type: Theme.animation.elementMoveFast.type
                easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animation.elementMoveFast.duration
                easing.type: Theme.animation.elementMoveFast.type
                easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
            }
        }

        Row {
            id: specialContent
            anchors.centerIn: parent
            spacing: iconSpacing

            Repeater {
                model: root.specialApps

                Item {
                    width: iconSize
                    height: iconSize
                    property var appData: modelData

                    Text {
                        anchors.centerIn: parent
                        font.family: BarStyle.iconFont
                        font.pixelSize: iconSize
                        text: AppIcons.getIcon(appData.class, appData.title, appData.xdgTag)
                        color: Theme.primaryText
                    }

                    Rectangle {
                        visible: appData.count > 1
                        anchors {
                            top: parent.top
                            right: parent.right
                            topMargin: -1
                            rightMargin: -1
                        }
                        width: Math.max(14, specialCountText.width + 4)
                        height: 14
                        radius: 5
                        color: Theme.colLayer0
                        border.width: 1
                        border.color: Theme.primary

                        Text {
                            id: specialCountText
                            anchors.centerIn: parent
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.primary
                            text: appData.count
                        }
                    }
                }
            }
        }
    }
}
