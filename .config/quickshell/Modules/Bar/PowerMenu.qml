pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components"

BarPopout {
    id: root

    WlrLayershell.namespace: "bidshell:power-menu"
    panelWidth: 232
    padding: 6

    onPanelClosed: list.shutdownArmed = false

    PowerMenuList {
        id: list

        anchors.fill: parent
        keysFor: Compositor.keysFor
        // A device that would be left with a low battery gets a reminder instead
        shutDown: () => {
            if (PeripheralBatteries.getLowBatteryDevices().length > 0)
                Settings.shutdownReminderVisible = true;
            else
                PowerActions.poweroff();
        }
        onChosen: root.hidePanel()
    }
}
