import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../Config"
import "../../../Components"
import "../../../Services"
import "../../../Utils"

ColumnLayout {
    id: root

    spacing: Theme.spacingBase

    // Disabled state - centered icon and text
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !Network.wifiEnabled

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spacingBase

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "WiFi disabled"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textSecondary
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Icons.wifiOff
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 64
                color: Theme.textSecondary
            }
        }
    }

    // Ethernet status (if connected)
    Rectangle {
        Layout.fillWidth: true
        visible: Network.ethernet
        height: 40
        radius: Theme.radiusBase
        color: Theme.alpha(Theme.primary, 0.15)

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingBase
            spacing: Theme.spacingBase

            Text {
                text: Icons.network
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeBase + 4
                color: Theme.primary
            }

            StyledText {
                Layout.fillWidth: true
                text: "Ethernet connected"
                font.pixelSize: Theme.fontSizeBase
                color: Theme.primary
            }
        }
    }

    // Scanning indicator
    Rectangle {
        Layout.fillWidth: true
        visible: Network.wifiScanning && Network.wifiEnabled
        height: 4
        radius: 2
        color: Theme.colLayer2

        Rectangle {
            id: scanningBar
            width: parent.width * 0.3
            height: parent.height
            radius: 2
            color: Theme.primary

            SequentialAnimation on x {
                running: Network.wifiScanning
                loops: Animation.Infinite
                NumberAnimation {
                    from: 0
                    to: scanningBar.parent.width - scanningBar.width
                    duration: 800
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    from: scanningBar.parent.width - scanningBar.width
                    to: 0
                    duration: 800
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // Network list
    ScrollView {
        id: scrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 100
        visible: Network.wifiEnabled

        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 4

            Repeater {
                model: ScriptModel {
                    values: Network.friendlyWifiNetworks
                }

                NetworkItem {
                    required property var modelData
                    Layout.fillWidth: true
                    network: modelData
                }
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: emptyText.height + Theme.spacingLarge * 2
                visible: Network.friendlyWifiNetworks.length === 0 && Network.wifiEnabled && !Network.wifiScanning

                StyledText {
                    id: emptyText
                    anchors.centerIn: parent
                    text: "No networks found"
                    font.pixelSize: Theme.fontSizeBase
                    color: Theme.textSecondary
                }
            }
        }
    }

    // Footer button
    Button {
        Layout.fillWidth: true
        text: "Scan"
        enabled: Network.wifiEnabled && !Network.wifiScanning
        onClicked: Network.rescanWifi()
    }

    Component.onCompleted: {
        Logger.info("Network tab loaded");
    }
}
