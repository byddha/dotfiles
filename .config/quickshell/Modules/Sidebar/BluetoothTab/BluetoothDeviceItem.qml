import QtQuick
import "../../../Components"
import "../../../Services"

ExpandableListItem {
    id: root

    required property var device

    active: device?.connected ?? false
    icon: Bluetooth.getDeviceIcon(device?.icon ?? "")
    title: device?.name ?? "Unknown device"
    subtitleVisible: (device?.connected || device?.paired) ?? false
    subtitle: {
        if (!device?.paired)
            return "";
        let status = device?.connected ? "Connected" : "Paired";
        if (device?.batteryAvailable) {
            status += ` • ${Math.round(device.battery * 100)}%`;
        }
        return status;
    }
    actionText: device?.connected ? "Disconnect" : "Connect"
    onActionClicked: {
        if (device?.connected) {
            device.disconnect();
        } else {
            device.connect();
        }
    }
}
