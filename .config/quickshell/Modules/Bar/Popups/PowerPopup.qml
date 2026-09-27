pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Wayland
import "../../../Config"
import "../../../Components"
import "../../../Services"

Popout {
    id: powerPopup

    WlrLayershell.namespace: "bidshell:power-popup"
    padding: Theme.spacingBase

    Row {
        anchors.fill: parent
        spacing: Theme.spacingBase

        PowerActionButton {
            icon: Icons.shutdown
            onClicked: {
                const lowDevices = PeripheralBatteries.getLowBatteryDevices();
                if (lowDevices.length === 0) {
                    PowerActions.poweroff();
                } else {
                    Settings.shutdownReminderVisible = true;
                }
                powerPopup.hidePanel();
            }
        }
        PowerActionButton {
            icon: Icons.reboot
            onClicked: {
                PowerActions.reboot();
                powerPopup.hidePanel();
            }
        }
        PowerActionButton {
            icon: Icons.logout
            onClicked: {
                PowerActions.logout();
                powerPopup.hidePanel();
            }
        }
        PowerActionButton {
            icon: Icons.suspend
            onClicked: {
                PowerActions.suspend();
                powerPopup.hidePanel();
            }
        }
    }
}
