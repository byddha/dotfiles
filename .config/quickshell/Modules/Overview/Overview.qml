import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Config"
import "../../Services"
import "../../Utils"
import "."

Scope {
    id: overviewScope

    Variants {
        id: overviewVariants
        model: Quickshell.screens
        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
            screen: modelData
            visible: Settings.overviewVisible && monitorIsFocused

            WlrLayershell.namespace: "bidshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors {
                right: true
                bottom: true
            }

            WlrLayershell.margins {
                right: Settings.sidebarVisible ? (Config.options.sidebar.width + 50) : 100
                bottom: 100
            }

            implicitWidth: columnLayout.implicitWidth
            implicitHeight: columnLayout.implicitHeight

            ColumnLayout {
                id: columnLayout
                visible: Settings.overviewVisible
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }

                Loader {
                    id: overviewLoader
                    active: Settings.overviewVisible && (Config?.options.overview.enabled ?? true)
                    sourceComponent: OverviewWidget {
                        panelWindow: root
                        visible: true
                    }
                }
            }
        }
    }

    // Auto-show/hide logic using Hyprland IPC events
    Timer {
        id: autoHideTimer
        interval: 500
        repeat: false
        onTriggered: {
            Settings.overviewVisible = false;
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            // Listen for workspace and monitor focus change events
            if (event.name === "workspace" || event.name === "workspacev2" || event.name === "focusedmon" || event.name === "focusedmonv2") {
                Settings.overviewVisible = true;
                autoHideTimer.restart();
            }
        }
    }

    // IPC handlers for overview control
    // These can be called via the IPC module
    Component.onCompleted: {
        Logger.info("Overview module loaded");
    }
}
