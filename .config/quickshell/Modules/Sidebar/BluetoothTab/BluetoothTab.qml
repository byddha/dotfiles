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

    // Tabs stay loaded, so refresh each time this tab is shown
    onShownChanged: {
        if (shown)
            Bluetooth.refresh();
    }
    Component.onCompleted: {
        if (shown)
            Bluetooth.refresh();
    }

    EmptyState {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !Bluetooth.enabled
        text: "Bluetooth disabled"
        icon: Icons.bluetoothOff
    }

    ScrollList {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: Bluetooth.enabled

        SectionHeader {
            first: true
            visible: Bluetooth.connectedDevices.length > 0
            text: "Connected"
            meta: Bluetooth.connectedDevices.length
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

        SectionHeader {
            first: Bluetooth.connectedDevices.length === 0
            visible: Bluetooth.pairedDevices.length > 0
            text: "Paired devices"
            meta: Bluetooth.pairedDevices.length
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

        EmptyState {
            Layout.fillWidth: true
            visible: Bluetooth.deviceList.length === 0
            text: "No paired devices"
            icon: Icons.bluetoothOn
        }
    }

    ListFooter {
        meta: `${Bluetooth.deviceList.length} device${Bluetooth.deviceList.length === 1 ? "" : "s"}`
        actionText: "Advanced Settings"
        actionIcon: Icons.tune
        onActionClicked: Quickshell.execDetached(["blueman-manager"])
    }
}
