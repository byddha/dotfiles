import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../Config"
import "../../../Components"
import "../../../Services"

ReversibleGrid {
    id: root

    property bool shown: false

    reversed: Placement.sidebarReversed

    ScrollList {
        Layout.fillWidth: true
        Layout.fillHeight: true
        reversed: root.reversed

        // Ethernet banner
        Rectangle {
            Layout.fillWidth: true
            // The gap faces the Wi-Fi list
            Layout.topMargin: root.reversed ? 8 : 0
            Layout.bottomMargin: root.reversed ? 0 : 8
            visible: Network.ethernet
            implicitHeight: 40
            radius: Theme.radiusBase
            color: Theme.alpha(Theme.primary, Theme.stateSelected)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12

                Item {
                    implicitWidth: 32
                    implicitHeight: Theme.iconSizeLarge

                    Icon {
                        anchors.centerIn: parent
                        text: Lucide.ethernetPort
                        size: Theme.iconSizeLarge
                        color: Theme.primary
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Ethernet connected"
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        EmptyState {
            Layout.fillWidth: true
            visible: !Network.wifiEnabled
            text: "Wi-Fi disabled"
            icon: Lucide.wifiOff
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: Network.wifiEnabled
            spacing: 2

            SectionHeader {
                text: "Wi-Fi networks"
                meta: Network.wifiScanning ? "Scanning…" : ""
                metaIcon: Network.wifiScanning ? Lucide.refreshCw : ""
                metaColor: Theme.primary
            }

            Repeater {
                model: ScriptModel {
                    values: Network.wifiEnabled ? Network.friendlyWifiNetworks : []
                }

                NetworkItem {
                    required property var modelData
                    Layout.fillWidth: true
                    network: modelData
                }
            }

            EmptyState {
                Layout.fillWidth: true
                visible: !Network.wifiScanning && Network.friendlyWifiNetworks.length === 0
                text: "No networks found"
                icon: Lucide.wifi
            }
        }
    }

    ListFooter {
        visible: Network.wifiEnabled
        meta: `${Network.friendlyWifiNetworks.length} network${Network.friendlyWifiNetworks.length === 1 ? "" : "s"}`
        actionText: "Scan"
        actionIcon: Lucide.refreshCw
        actionEnabled: !Network.wifiScanning
        onActionClicked: Network.rescanWifi()
    }
}
