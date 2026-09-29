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

            // From the screen edges, or from the bar where it is
            readonly property int gap: 10

            closeOnDismiss: false
            useFocusGrab: true
            slideFrom: Placement.sidebarSide
            slideClip: BarLayout.reservedAt(Placement.sidebarSide)
            padding: 12
            // As tall as its content, up to the gaps at both ends (or the bar there); then the open tab
            // scrolls. Anchored to the bottom it stands on its bottom gap and grows up.
            panelWidth: Theme.sidebarWidth
            maxPanelHeight: modelData.height - Placement.inset("top", gap) - Placement.inset("bottom", gap)
            panelX: Placement.sidebarSide === "left" ? Placement.inset("left", gap) : modelData.width - Placement.inset("right", gap) - Theme.sidebarWidth
            panelY: Placement.sidebarReversed ? modelData.height - Placement.inset("bottom", gap) - panelSize.height : Placement.inset("top", gap)

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
