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
        icon: Lucide.bluetoothOff
    }

    ScrollList {
        Layout.fillWidth: true
        Layout.fillHeight: true
        // Whole sections swap places when reversed; each still reads top to bottom
        reversed: root.reversed
        spacing: 14
        visible: Bluetooth.enabled

        DeviceGroup {
            title: "Connected"
            devices: Bluetooth.connectedDevices
        }

        DeviceGroup {
            title: "Paired devices"
            devices: Bluetooth.pairedDevices
        }

        EmptyState {
            Layout.fillWidth: true
            visible: Bluetooth.deviceList.length === 0
            text: "No paired devices"
            icon: Lucide.bluetooth
        }
    }

    ListFooter {
        meta: `${Bluetooth.deviceList.length} device${Bluetooth.deviceList.length === 1 ? "" : "s"}`
        actionText: "Advanced Settings"
        actionIcon: Lucide.slidersHorizontal
        onActionClicked: Quickshell.execDetached(["blueman-manager"])
    }

    component DeviceGroup: ColumnLayout {
        id: group

        property string title
        property var devices

        Layout.fillWidth: true
        visible: devices.length > 0
        spacing: 2

        SectionHeader {
            text: group.title
            meta: group.devices.length
        }

        Repeater {
            model: ScriptModel {
                values: group.devices
            }

            BluetoothDeviceItem {
                required property var modelData
                Layout.fillWidth: true
                device: modelData
            }
        }
    }
}
