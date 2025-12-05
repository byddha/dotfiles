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
        visible: !Bluetooth.enabled

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spacingBase

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Bluetooth disabled"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textSecondary
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Icons.bluetoothOff
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 64
                color: Theme.textSecondary
            }
        }
    }

    // Device list
    ScrollView {
        id: scrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 100
        visible: Bluetooth.enabled

        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 4

            // Connected devices section
            StyledText {
                Layout.fillWidth: true
                visible: Bluetooth.connectedDevices.length > 0
                text: "Connected"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
            }

            Repeater {
                model: ScriptModel {
                    values: Bluetooth.connectedDevices
                }

                BluetoothDeviceItem {
                    required property var modelData
                    Layout.fillWidth: true
                    device: modelData
                }
            }

            // Paired devices section
            StyledText {
                Layout.fillWidth: true
                visible: Bluetooth.pairedDevices.length > 0
                Layout.topMargin: Bluetooth.connectedDevices.length > 0 ? Theme.spacingBase : 0
                text: "Paired Devices"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
            }

            Repeater {
                model: ScriptModel {
                    values: Bluetooth.pairedDevices
                }

                BluetoothDeviceItem {
                    required property var modelData
                    Layout.fillWidth: true
                    device: modelData
                }
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: emptyText.height + Theme.spacingLarge * 2
                visible: Bluetooth.deviceList.length === 0 && Bluetooth.enabled

                StyledText {
                    id: emptyText
                    anchors.centerIn: parent
                    text: "No paired devices"
                    font.pixelSize: Theme.fontSizeBase
                    color: Theme.textSecondary
                }
            }
        }
    }

    // Advanced settings button
    Button {
        Layout.fillWidth: true
        text: "Advanced Settings"
        onClicked: Quickshell.execDetached(["blueman-manager"])
    }

    // Refresh when tab becomes visible
    onVisibleChanged: {
        if (visible) {
            Bluetooth.refresh()
        }
    }

    Component.onCompleted: {
        Logger.info("Bluetooth tab loaded")
        Bluetooth.refresh()
    }
}
