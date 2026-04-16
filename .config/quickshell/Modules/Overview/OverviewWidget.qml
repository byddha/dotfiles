import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Utils"
import "../../Components"
import "."

Item {
    id: root
    required property var panelWindow
    // Monitor snapshot — refreshed via Compositor signals
    property var monitorInfo: Compositor.monitorForScreen(panelWindow.screen)
    readonly property string monitorName: monitorInfo?.name ?? ""
    readonly property string monitorModel: monitorInfo?.model ?? ""
    readonly property int monitorId: monitorInfo?.id ?? -1
    readonly property var toplevels: ToplevelManager.toplevels
    // Get all workspaces assigned to this monitor from centralized config
    readonly property var currentMonitorWorkspaces: {
        const monitorConfig = Config.options?.monitors?.[monitorModel];
        const range = monitorConfig?.workspaces;
        if (!range || range[0] === undefined || range[1] === undefined) {
            return [];
        }
        const workspaces = [];
        for (let i = range[0]; i <= range[1]; i++) {
            workspaces.push(i);
        }
        return workspaces;
    }
    property bool monitorIsFocused: Compositor.focusedMonitorName === monitorName
    property var windows: Compositor.windowList
    property var windowByAddress: Compositor.windowByAddress
    property var windowAddresses: Compositor.addresses
    property real scale: Config.options.overview.scale
    property color activeBorderColor: Theme.colSecondary

    property real workspaceImplicitWidth: (monitorInfo?.transform % 2 === 1) ? ((monitorInfo.height / monitorInfo.scale - (monitorInfo?.reserved?.[0] ?? 0) - (monitorInfo?.reserved?.[2] ?? 0)) * root.scale) : ((monitorInfo.width / monitorInfo.scale - (monitorInfo?.reserved?.[0] ?? 0) - (monitorInfo?.reserved?.[2] ?? 0)) * root.scale)
    property real workspaceImplicitHeight: (monitorInfo?.transform % 2 === 1) ? ((monitorInfo.width / monitorInfo.scale - (monitorInfo?.reserved?.[1] ?? 0) - (monitorInfo?.reserved?.[3] ?? 0)) * root.scale) : ((monitorInfo.height / monitorInfo.scale - (monitorInfo?.reserved?.[1] ?? 0) - (monitorInfo?.reserved?.[3] ?? 0)) * root.scale)

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: 250 * (monitorInfo?.scale ?? 1)
    property int workspaceZ: 0
    property int windowZ: 1
    property int indicatorZ: 9999
    property real workspaceSpacing: 5

    // Refresh monitor snapshot when data updates
    Connections {
        target: Compositor
        function onMonitorDataUpdated() {
            root.monitorInfo = Compositor.monitorForScreen(panelWindow.screen);
        }
        function onWorkspaceFocusChanged() {
            root.monitorInfo = Compositor.monitorForScreen(panelWindow.screen);
        }
    }

    implicitWidth: overviewBackground.implicitWidth + Theme.elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + Theme.elevationMargin * 2

    Rectangle { // Background
        id: overviewBackground
        property real padding: 10
        anchors.fill: parent
        anchors.margins: Theme.elevationMargin

        implicitWidth: workspaceColumnLayout.implicitWidth + padding * 2
        implicitHeight: workspaceColumnLayout.implicitHeight + padding * 2
        radius: Theme.roundingScreen * root.scale + padding
        color: Theme.colLayer0
        border.width: 1
        border.color: Theme.colLayer0Border

        ColumnLayout { // Workspaces and monitor indicators
            id: workspaceColumnLayout

            z: root.workspaceZ
            anchors.centerIn: parent
            spacing: workspaceSpacing

            Repeater {
                // Workspace repeater
                model: root.currentMonitorWorkspaces
                Rectangle { // Workspace
                    id: workspace
                    required property int modelData
                    required property int index
                    property int workspaceValue: modelData

                    implicitWidth: root.workspaceImplicitWidth
                    implicitHeight: root.workspaceImplicitHeight
                    color: Theme.colLayer1
                    radius: Theme.roundingScreen * root.scale
                    border.width: 2
                    border.color: "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: workspaceValue
                        font {
                            pixelSize: root.workspaceNumberSize * root.scale
                            weight: Font.DemiBold
                            family: Theme.fontFamily
                        }
                        color: ColorUtils.transparentize(Theme.colOnLayer1, 0.8)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Monitor indicators
            RowLayout {
                id: monitorIndicators
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: workspaceSpacing * 2
                spacing: 8

                Repeater {
                    model: Compositor.monitors
                    Rectangle {
                        id: monitorIndicator
                        required property var modelData
                        required property int index
                        property bool isCurrentMonitor: modelData.id === root.monitorId
                        property int activeWorkspaceId: modelData.activeWorkspace?.id ?? 1

                        implicitWidth: isCurrentMonitor ? 60 : 48
                        implicitHeight: isCurrentMonitor ? 36 : 28
                        radius: 4
                        color: isCurrentMonitor ? Theme.colSecondary : Theme.colLayer2
                        border.width: isCurrentMonitor ? 2 : 1
                        border.color: isCurrentMonitor ? Theme.colSecondary : Theme.colLayer2

                        Behavior on implicitWidth {
                            animation: Theme.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on implicitHeight {
                            animation: Theme.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: activeWorkspaceId
                            font {
                                pixelSize: isCurrentMonitor ? Theme.fontSizeSmall : Theme.fontSizeTiny
                                weight: Font.Bold
                            }
                            color: isCurrentMonitor ? Theme.primaryText : Theme.colOnLayer1
                        }
                    }
                }
            }
        }

        Item { // Windows & focused workspace indicator
            id: windowSpace
            anchors.centerIn: parent
            implicitWidth: workspaceColumnLayout.implicitWidth
            implicitHeight: workspaceColumnLayout.implicitHeight

            Repeater {
                // Window repeater
                model: ScriptModel {
                    values: {
                        return ToplevelManager.toplevels.values.filter(toplevel => {
                            var win = Compositor.windowForToplevel(toplevel);
                            // Only show windows on current monitor's workspaces
                            const onCurrentMonitor = win?.monitor === root.monitorId;
                            const inCurrentWorkspaces = root.currentMonitorWorkspaces.includes(win?.workspace?.id);
                            return onCurrentMonitor && inCurrentWorkspaces;
                        }).sort((a, b) => {
                            // Proper stacking order based on window properties
                            const winA = Compositor.windowForToplevel(a);
                            const winB = Compositor.windowForToplevel(b);

                            // 1. Pinned windows are always on top
                            if (winA?.pinned !== winB?.pinned) {
                                return winA?.pinned ? 1 : -1;
                            }

                            // 2. Floating windows above tiled windows
                            if (winA?.floating !== winB?.floating) {
                                return winA?.floating ? 1 : -1;
                            }

                            // 3. Within same category, sort by focus history
                            // Lower focusHistoryID = more recently focused = higher in stack
                            return (winB?.focusHistoryID ?? 0) - (winA?.focusHistoryID ?? 0);
                        });
                    }
                }
                delegate: OverviewWindow {
                    id: window
                    required property var modelData
                    required property int index
                    windowData: Compositor.windowForToplevel(modelData)
                    toplevel: modelData
                    monitorData: root.monitorInfo

                    property real sourceMonitorWidth: (monitorData?.transform % 2 === 1) ? (root.monitorInfo.height / root.monitorInfo.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0)) : (root.monitorInfo.width / root.monitorInfo.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0))
                    property real sourceMonitorHeight: (monitorData?.transform % 2 === 1) ? (root.monitorInfo.width / root.monitorInfo.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0)) : (root.monitorInfo.height / root.monitorInfo.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0))

                    scale: Math.min(root.workspaceImplicitWidth / sourceMonitorWidth, root.workspaceImplicitHeight / sourceMonitorHeight)

                    availableWorkspaceWidth: root.workspaceImplicitWidth
                    availableWorkspaceHeight: root.workspaceImplicitHeight
                    widgetMonitorId: root.monitorId

                    // Find workspace index in current monitor's workspace list
                    property int workspaceIndex: root.currentMonitorWorkspaces.indexOf(windowData?.workspace?.id ?? 1)

                    // Simple linear offset calculation
                    xOffset: 0
                    yOffset: workspaceIndex * (root.workspaceImplicitHeight + workspaceSpacing)

                    z: root.windowZ + index
                }
            }

            Rectangle { // Focused workspace indicator
                id: focusedWorkspaceIndicator
                property int activeWorkspaceId: root.monitorInfo?.activeWorkspaceId ?? 1
                property int activeWorkspaceIndex: root.currentMonitorWorkspaces.indexOf(activeWorkspaceId)

                // Simple linear position calculation
                x: 0
                y: activeWorkspaceIndex * (root.workspaceImplicitHeight + workspaceSpacing)

                z: root.indicatorZ
                width: root.workspaceImplicitWidth
                height: root.workspaceImplicitHeight
                color: "transparent"
                radius: Theme.roundingScreen * root.scale
                border.width: 2
                border.color: root.activeBorderColor
                Behavior on x {
                    animation: Theme.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on y {
                    animation: Theme.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
