import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components/Notifications"

Scope {
    readonly property string primaryMonitorModel: Config.primaryMonitor

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: notificationPopup

            required property ShellScreen modelData
            screen: modelData

            visible: (Notifications.popupList.length > 0) && modelData.model === primaryMonitorModel

            WlrLayershell.namespace: "bidshell:notificationPopup"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0

            anchors {
                right: true
                bottom: true
            }

            // Room on every side for the card shadows, as in DankMaterialShell's windowShadowPad.
            // The mask keeps that room click-through; the margins keep cards 2 * spacingBase from the edge.
            readonly property int shadowPad: 16

            WlrLayershell.margins {
                right: Theme.spacingBase * 2 - shadowPad
                bottom: Theme.spacingBase * 2 - shadowPad
            }

            mask: Region {
                item: listview.contentItem
            }

            color: "transparent"
            implicitWidth: 400 - Theme.spacingBase * 2 + shadowPad * 2
            implicitHeight: listview.height + shadowPad * 2

            NotificationListView {
                id: listview
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    bottomMargin: notificationPopup.shadowPad
                    rightMargin: notificationPopup.shadowPad
                }
                width: parent.width - notificationPopup.shadowPad * 2
                height: Math.min(implicitHeight, screen.height * 0.8)  // Allow up to 80% of screen height
                popup: true
            }
        }
    }
}
