import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        Popout {
            id: sidebarWindow
            required property ShellScreen modelData

            targetScreen: modelData
            visible: Settings.sidebarVisible && modelData.name === Compositor.focusedMonitorName

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "bidshell:sidebar"

            closeOnDismiss: false
            useFocusGrab: true
            slideFromRight: true
            padding: 12
            // As tall as its content, down to 10 px above the screen edge; then the open tab scrolls
            panelWidth: Theme.sidebarWidth
            maxPanelHeight: modelData.height - 60
            panelX: modelData.width - Theme.sidebarWidth - 10
            panelY: 50

            onDismissed: Settings.sidebarVisible = false
            onVisibleChanged: {
                if (visible)
                    Hdr.refresh();
            }

            Loader {
                anchors.fill: parent
                active: sidebarWindow.contentWarm
                sourceComponent: SidebarContent {
                    shown: sidebarWindow.visible
                }
            }
        }
    }
}
