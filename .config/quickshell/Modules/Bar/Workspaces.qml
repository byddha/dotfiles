import QtQuick
import Quickshell
import "../../Config"
import "../../Services"

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
    readonly property string screenName: root.QsWindow.window && root.QsWindow.window.screen ? root.QsWindow.window.screen.name : ""
    readonly property var workspaceItems: buildWorkspaceItems()

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

    component FastAnim: NumberAnimation {
        duration: Theme.animation.elementMoveFast.duration
        easing.type: Theme.animation.elementMoveFast.type
        easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
    }

    component AppIcon: Item {
        id: appIcon

        property var appData
        property real size
        property color iconColor
        property color badgeColor
        property color badgeBorderColor
        property color badgeTextColor

        width: size
        height: size

        Text {
            anchors.centerIn: parent
            font.family: BarStyle.iconFont
            font.pixelSize: appIcon.size
            text: AppIcons.getIcon(appIcon.appData.class, appIcon.appData.title, appIcon.appData.xdgTag)
            color: appIcon.iconColor
        }

        // Count badge (only if count > 1)
        Rectangle {
            visible: appIcon.appData.count > 1
            anchors {
                top: parent.top
                right: parent.right
                topMargin: -1
                rightMargin: -1
            }
            width: Math.max(14, countText.width + 4)
            height: 14
            radius: 5
            color: appIcon.badgeColor
            border.width: 1
            border.color: appIcon.badgeBorderColor

            Text {
                id: countText
                anchors.centerIn: parent
                font.pixelSize: 10
                font.weight: Font.Bold
                color: appIcon.badgeTextColor
                text: appIcon.appData.count
            }
        }
    }

    implicitWidth: workspaceBackground.width + (root.specialVisible ? specialPill.width + BarStyle.spacing : 0)
    implicitHeight: BarStyle.barHeight

    // Find next occupied workspace in a direction (1 = forward, -1 = backward)
    function findNextOccupied(currentId, direction) {
        const count = workspaceItems.length;
        if (count === 0)
            return currentId;

        const currentIndex = workspaceItems.findIndex(ws => workspaceId(ws) === currentId);
        const startIndex = currentIndex >= 0 ? currentIndex : 0;
        const wrap = index => ((index % count) + count) % count;

        if (!Compositor.isNiri) {
            for (let i = 1; i <= count; i++) {
                const nextWorkspace = workspaceItems[wrap(startIndex + direction * i)];
                if (workspaceIsOccupied(nextWorkspace))
                    return workspaceId(nextWorkspace);
            }
        }

        return workspaceId(workspaceItems[wrap(startIndex + direction)]);
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
            FastAnim {}
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

                            AppIcon {
                                appData: modelData
                                size: root.iconSize
                                iconColor: workspaceContainer.isActive ? Theme.primary : BarStyle.iconColor
                                badgeColor: iconColor
                                badgeBorderColor: Theme.colLayer0
                                badgeTextColor: Theme.primaryText
                            }
                        }
                    }
                }

                // Width animation
                Behavior on contentWidth {
                    FastAnim {}
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
            FastAnim {}
        }

        Behavior on width {
            FastAnim {}
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
            FastAnim {}
        }

        Behavior on opacity {
            FastAnim {}
        }

        Row {
            id: specialContent
            anchors.centerIn: parent
            spacing: iconSpacing

            Repeater {
                model: root.specialApps

                AppIcon {
                    appData: modelData
                    size: root.iconSize
                    iconColor: Theme.primaryText
                    badgeColor: Theme.colLayer0
                    badgeBorderColor: Theme.primary
                    badgeTextColor: Theme.primary
                }
            }
        }
    }
}
