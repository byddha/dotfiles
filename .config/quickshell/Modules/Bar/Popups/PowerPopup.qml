pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Wayland
import "../../../Config"
import "../../../Components"
import "../../../Services"

BarPopup {
    id: powerPopup

    offsetY: anchorItem ? anchorItem.height + 4 : 0

    WlrLayershell.namespace: "bidshell:power-popup"

    Rectangle {
        id: panelBg
        width: buttonsRow.implicitWidth + Theme.spacingBase * 2
        height: buttonsRow.implicitHeight + Theme.spacingBase * 2
        implicitWidth: width
        implicitHeight: height
        color: Theme.colLayer0
        radius: Theme.radiusWindow
        border.color: Theme.popupBorder
        border.width: 1

        Row {
            id: buttonsRow
            anchors.centerIn: parent
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
}
