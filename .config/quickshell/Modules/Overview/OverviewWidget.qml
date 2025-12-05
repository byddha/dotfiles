import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Config"
import "../../Services"
import "../../Utils"
import "../../Components"
import "."

Item {
    id: root
    required property var panelWindow
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    readonly property string monitorName: monitor?.name ?? ""
    readonly property var toplevels: ToplevelManager.toplevels
    // Get all workspaces assigned to this monitor from centralized config
    readonly property var currentMonitorWorkspaces: {
        const monitorConfig = Config.options?.monitors?.[monitorName];
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
    property bool monitorIsFocused: (Hyprland.focusedMonitor?.name == monitor.name)
    property var windows: HyprlandData.windowList
    property var windowByAddress: HyprlandData.windowByAddress
    property var windowAddresses: HyprlandData.addresses
    property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor?.id)
    property real scale: Config.options.overview.scale
    property color activeBorderColor: Theme.colSecondary

    property real workspaceImplicitWidth: (monitorData?.transform % 2 === 1) ? ((monitor.height / monitor.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0)) * root.scale) : ((monitor.width / monitor.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0)) * root.scale)
    property real workspaceImplicitHeight: (monitorData?.transform % 2 === 1) ? ((monitor.width / monitor.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0)) * root.scale) : ((monitor.height / monitor.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0)) * root.scale)

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: 250 * monitor.scale
    property int workspaceZ: 0
    property int windowZ: 1
    property int indicatorZ: 9999
    property real workspaceSpacing: 5

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
                    model: HyprlandData.monitors
                    Rectangle {
                        id: monitorIndicator
                        required property var modelData
                        required property int index
                        property bool isCurrentMonitor: modelData.id === root.monitor?.id
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
                            const address = `0x${toplevel.HyprlandToplevel.address}`;
                            var win = windowByAddress[address];
                            // Only show windows on current monitor's workspaces
                            const onCurrentMonitor = win?.monitor === root.monitor?.id;
                            const inCurrentWorkspaces = root.currentMonitorWorkspaces.includes(win?.workspace?.id);
                            return onCurrentMonitor && inCurrentWorkspaces;
                        }).sort((a, b) => {
                            // Proper stacking order based on Hyprland's window properties
                            const addrA = `0x${a.HyprlandToplevel.address}`;
                            const addrB = `0x${b.HyprlandToplevel.address}`;
                            const winA = windowByAddress[addrA];
                            const winB = windowByAddress[addrB];

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
                    property var address: `0x${modelData.HyprlandToplevel.address}`
                    windowData: windowByAddress[address]
                    toplevel: modelData
                    monitorData: root.monitorData

                    property real sourceMonitorWidth: (monitorData?.transform % 2 === 1) ? (root.monitor.height / root.monitor.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0)) : (root.monitor.width / root.monitor.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0))
                    property real sourceMonitorHeight: (monitorData?.transform % 2 === 1) ? (root.monitor.width / root.monitor.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0)) : (root.monitor.height / root.monitor.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0))

                    scale: Math.min(root.workspaceImplicitWidth / sourceMonitorWidth, root.workspaceImplicitHeight / sourceMonitorHeight)

                    availableWorkspaceWidth: root.workspaceImplicitWidth
                    availableWorkspaceHeight: root.workspaceImplicitHeight
                    widgetMonitorId: root.monitor.id

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
                property int activeWorkspaceId: monitor.activeWorkspace?.id ?? 1
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
