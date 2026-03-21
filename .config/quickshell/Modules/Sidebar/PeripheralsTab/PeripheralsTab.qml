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

    // Empty state
    ColumnLayout {
        visible: Peripherals.devices.length === 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.spacingBase

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Icons.device
            font.family: Theme.fontFamilyIcons
            font.pixelSize: 32
            color: Theme.textSecondary
            opacity: 0.5
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "No peripherals detected"
            font.pixelSize: Theme.fontSizeBase
            color: Theme.textSecondary
        }

        Item { Layout.fillHeight: true }
    }

    // Device list
    ScrollView {
        visible: Peripherals.devices.length > 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 2

            Repeater {
                model: ScriptModel { values: Peripherals.devices }

                PeripheralDeviceItem {
                    required property var modelData
                    Layout.fillWidth: true
                    device: modelData
                }
            }
        }
    }

    Component.onCompleted: {
        PeripheralBatteries.repollRequested();
    }
}
