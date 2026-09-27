import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../Config"
import "../../../Components"
import "../../../Services"

ColumnLayout {
    id: root

    property bool shown: false

    spacing: 0

    ScrollList {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Ethernet banner
        Rectangle {
            Layout.fillWidth: true
            Layout.bottomMargin: 8
            visible: Network.ethernet
            implicitHeight: 40
            radius: Theme.radiusBase
            color: Theme.alpha(Theme.primary, Theme.stateSelected)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12

                Text {
                    Layout.preferredWidth: 32
                    horizontalAlignment: Text.AlignHCenter
                    text: Icons.ethernet
                    font.family: Theme.fontFamilyGlyphs
                    font.pixelSize: 20
                    color: Theme.primary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Ethernet connected"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.textColor
                }
            }
        }

        EmptyState {
            Layout.fillWidth: true
            visible: !Network.wifiEnabled
            text: "Wi-Fi disabled"
            icon: Icons.wifiOff
        }

        SectionHeader {
            first: true
            visible: Network.wifiEnabled
            text: "Wi-Fi networks"
            meta: Network.wifiScanning ? "Scanning…" : ""
            metaIcon: Network.wifiScanning ? Icons.refresh : ""
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
            visible: Network.wifiEnabled && !Network.wifiScanning && Network.friendlyWifiNetworks.length === 0
            text: "No networks found"
            icon: Icons.wifiOn
        }
    }

    ListFooter {
        visible: Network.wifiEnabled
        meta: `${Network.friendlyWifiNetworks.length} network${Network.friendlyWifiNetworks.length === 1 ? "" : "s"}`
        actionText: "Scan"
        actionIcon: Icons.refresh
        actionEnabled: !Network.wifiScanning
        onActionClicked: Network.rescanWifi()
    }
}
