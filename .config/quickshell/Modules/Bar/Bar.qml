import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Config"

Scope {
    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: bar

            required property ShellScreen modelData
            screen: modelData

            // Get monitor info for workspace configuration
            readonly property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(bar.screen)
            readonly property string monitorName: hyprMonitor?.name ?? ""

            // Workspace range - computed fresh each time dependencies change
            property var workspaceRange: null
            property bool hasWorkspaceConfig: false
            property int startWorkspace: 1
            property int endWorkspace: 1

            function updateWorkspaceConfig() {
                const monitors = Config.options?.monitors;
                const name = monitorName;

                if (!monitors || !name) {
                    workspaceRange = null;
                    hasWorkspaceConfig = false;
                    return;
                }

                const monitorConfig = monitors[name];
                const range = monitorConfig?.workspaces;
                if (range && range[0] !== undefined && range[1] !== undefined) {
                    workspaceRange = range;
                    hasWorkspaceConfig = true;
                    startWorkspace = range[0];
                    endWorkspace = range[1];
                } else {
                    workspaceRange = null;
                    hasWorkspaceConfig = false;
                }
            }

            onMonitorNameChanged: updateWorkspaceConfig()

            Connections {
                target: Config
                function onConfigLoadedChanged() {
                    if (Config.configLoaded) {
                        bar.updateWorkspaceConfig();
                    }
                }
            }

            Component.onCompleted: Qt.callLater(updateWorkspaceConfig)

            visible: Settings.barVisible && Config.options.bar.enabled

            anchors {
                top: Config.options.bar.position === "top"
                bottom: Config.options.bar.position === "bottom"
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Normal

            implicitHeight: BarStyle.barHeight + BarStyle.barMargin
            exclusiveZone: BarStyle.barHeight + BarStyle.barMargin
            color: "transparent"

            Rectangle {
                id: barBackground
                anchors.fill: parent
                anchors.topMargin: Config.options.bar.position === "bottom" ? BarStyle.barMargin : 0
                anchors.bottomMargin: Config.options.bar.position === "top" ? BarStyle.barMargin : 0
                color: BarStyle.barBackground
            }

            Row {
                id: leftSection
                height: barBackground.height
                anchors.left: barBackground.left
                anchors.leftMargin: BarStyle.spacing
                anchors.verticalCenter: barBackground.verticalCenter
                spacing: BarStyle.spacing

                PowerButton {}

                Loader {
                    active: Config.options?.bar?.tray?.enabled ?? true
                    height: parent.height
                    sourceComponent: Tray {
                        barWindow: bar
                    }
                }

                MediaButton {}
            }

            // Left-center section (expands leftward from workspaces)
            Row {
                id: leftCenterSection
                height: barBackground.height
                anchors.right: workspaces.left
                anchors.rightMargin: BarStyle.spacing
                anchors.verticalCenter: barBackground.verticalCenter
                spacing: BarStyle.spacing

                Clock {
                    barWindow: bar
                }
            }

            // Workspaces - always centered
            Workspaces {
                id: workspaces
                visible: bar.hasWorkspaceConfig
                startWorkspace: bar.startWorkspace
                endWorkspace: bar.endWorkspace
                anchors.horizontalCenter: barBackground.horizontalCenter
                anchors.verticalCenter: barBackground.verticalCenter
            }

            // Right-center section (expands rightward from workspaces)
            Row {
                id: rightCenterSection
                height: barBackground.height
                anchors.left: workspaces.right
                anchors.leftMargin: BarStyle.spacing
                anchors.verticalCenter: barBackground.verticalCenter
                spacing: BarStyle.spacing

                ActiveWindowTitle {}
            }

            // Right section
            Row {
                id: rightSection
                height: barBackground.height
                anchors.right: barBackground.right
                anchors.rightMargin: BarStyle.spacing
                anchors.verticalCenter: barBackground.verticalCenter
                spacing: BarStyle.spacing

                RecordingButton {}
                WhisperButton {}
                VpnButton {}
                BatteryButton {}
                MicButton {}
                VolumeButton {}

                NotificationButton {}
                NetworkButton {}
            }
        }
    }
}
