import QtQuick
import QtQuick.Layouts
import "../../../Components"
import "../../../Services"

ListRow {
    id: root

    required property var device

    leadIcon: Bluetooth.getDeviceIcon(device?.icon ?? "")
    title: device?.name ?? "Unknown device"
    subtitle: {
        let status = device?.connected ? "Connected" : "Paired";
        if (device?.batteryAvailable)
            status += ` • ${Math.round(device.battery * 100)}%`;
        return status;
    }
    selected: device?.connected ?? false
    expandable: true
    body: device?.connected ? disconnectBody : connectBody

    Component {
        id: connectBody
        RowLayout {
            FilledButton {
                text: "Connect"
                onClicked: {
                    root.device.connect();
                    root.expanded = false;
                }
            }
        }
    }

    Component {
        id: disconnectBody
        RowLayout {
            TextButton {
                text: "Disconnect"
                onClicked: {
                    root.device.disconnect();
                    root.expanded = false;
                }
            }
        }
    }
}
