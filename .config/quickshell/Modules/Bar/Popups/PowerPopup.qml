pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../../Config"
import "../../../Utils"
import "../../../Components"
import "../../../Services"

PopupWindow {
    id: powerPopup

    property var anchorItem: null

    signal panelOpened(window: var)
    signal panelClosed

    implicitWidth: buttonsRow.implicitWidth + Theme.spacingBase * 2
    implicitHeight: buttonsRow.implicitHeight + Theme.spacingBase * 2
    visible: false
    color: "transparent"

    anchor.item: anchorItem
    anchor.rect.x: anchorItem ? (anchorItem.width / 2) - (implicitWidth / 2) : 0
    anchor.rect.y: anchorItem ? anchorItem.height + 4 : 0

    onVisibleChanged: {
        if (!visible) {
            panelClosed();
        }
    }

    function showPanel(item) {
        if (!item) {
            Logger.warn("anchorItem is undefined, won't show panel.");
            return;
        }
        anchorItem = item;
        visible = true;
        panelOpened(powerPopup);
        Qt.callLater(() => powerPopup.anchor.updateAnchor());
        Logger.info("Panel opened");
    }

    function hidePanel() {
        visible = false;
        Logger.info("Panel hidden");
    }

    function executeCommand(args: list<string>) {
        Logger.info(`Executing: ${args.join(" ")}`);
        commandProcess.command = args;
        commandProcess.running = true;
        hidePanel();
    }

    Process {
        id: commandProcess
        onExited: exitCode => {
            if (exitCode !== 0) {
                Logger.error(`Command failed with exit code: ${exitCode}`);
            }
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: panelBg
            anchors.fill: parent
            color: Theme.colLayer0
            radius: Theme.radiusBase
            border.color: Theme.colLayer0Border
            border.width: 1

            Row {
                id: buttonsRow
                anchors.centerIn: parent
                spacing: Theme.spacingBase

                PowerActionButton {
                    icon: Icons.shutdown
                    onClicked: powerPopup.executeCommand(["systemctl", "poweroff"])
                }

                PowerActionButton {
                    icon: Icons.reboot
                    onClicked: powerPopup.executeCommand(["systemctl", "reboot"])
                }

                PowerActionButton {
                    icon: Icons.logout
                    onClicked: {
                        Logger.info("Logging out via Hyprland");
                        Hyprland.dispatch("exit");
                        powerPopup.hidePanel();
                    }
                }

                PowerActionButton {
                    icon: Icons.suspend
                    onClicked: powerPopup.executeCommand(["systemctl", "suspend"])
                }
            }
        }
    }
}
