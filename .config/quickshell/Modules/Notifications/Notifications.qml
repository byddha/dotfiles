import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Config"
import "../../Services"
import "../../Components/Notifications"
import "../../Utils"

Scope {
    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: notificationPopup

            required property ShellScreen modelData
            screen: modelData

            visible: (Notifications.popupList.length > 0) &&
                     Settings.notificationsVisible &&
                     Config?.options.notifications.enabled &&
                     modelData.name === Hyprland.focusedMonitor?.name

            WlrLayershell.namespace: "bidshell:notificationPopup"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0

            anchors {
                right: true
                bottom: true
            }

            WlrLayershell.margins {
                right: Theme.spacingBase
                bottom: Theme.spacingBase
            }

            mask: Region {
                item: listview.contentItem
            }

            color: "transparent"
            implicitWidth: 400
            implicitHeight: listview.height

            NotificationListView {
                id: listview
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    rightMargin: Theme.spacingBase
                    bottomMargin: Theme.spacingBase
                }
                width: parent.width - Theme.spacingBase * 2
                height: Math.min(implicitHeight, screen.height * 0.8)  // Allow up to 80% of screen height
                popup: true
            }
        }
    }

    Component.onCompleted: {
        Logger.info("Notification popup module loaded")
    }
}
