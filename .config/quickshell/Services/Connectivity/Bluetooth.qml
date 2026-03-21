pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../Utils"
import ".."

Singleton {
    id: root

    // Refresh trigger - increment to force list re-evaluation
    property int refreshTrigger: 0

    // Adapter state
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false

    // Sort function: named devices first, then by name alphabetically
    function sortDevices(a, b) {
        const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/;
        const aIsMac = macRegex.test(a.name);
        const bIsMac = macRegex.test(b.name);
        if (aIsMac !== bIsMac)
            return aIsMac ? 1 : -1;
        return a.name.localeCompare(b.name);
    }

    // Force refresh of device lists
    function refresh() {
        refreshTrigger++;
    }

    // Device lists (filtered and sorted) - depend on refreshTrigger for reactivity
    property list<var> connectedDevices: {
        refreshTrigger; // Dependency to force re-evaluation
        return Bluetooth.devices.values.filter(d => d.connected).sort(sortDevices);
    }
    property list<var> pairedDevices: {
        refreshTrigger; // Dependency to force re-evaluation
        return Bluetooth.devices.values.filter(d => d.paired && !d.connected).sort(sortDevices);
    }

    // Combined list: connected first, then paired
    property list<var> deviceList: {
        refreshTrigger; // Dependency to force re-evaluation
        return [...connectedDevices, ...pairedDevices];
    }

    // Watch for device list changes
    Connections {
        target: Bluetooth.devices
        function onObjectInsertedPost() {
            root.refresh();
        }
        function onObjectRemovedPost() {
            root.refresh();
        }
    }

    // Watch each device's connected state
    Instantiator {
        model: Bluetooth.devices
        delegate: Connections {
            required property BluetoothDevice modelData
            target: modelData
            function onConnectedChanged() {
                root.refresh();
            }
            function onPairedChanged() {
                root.refresh();
            }
        }
    }

    // Control functions
    function setEnabled(value: bool) {
        if (!Bluetooth.defaultAdapter) {
            Logger.error("No adapter available");
            return;
        }
        Bluetooth.defaultAdapter.enabled = value;
        Logger.info(`Adapter ${value ? "enabled" : "disabled"}`);
    }

    function toggleEnabled() {
        setEnabled(!enabled);
    }

    // Icon helper based on device type
    function getDeviceIcon(iconName: string): string {
        Logger.debug(`Icon name ${iconName}`);
        if (!iconName)
            return Icons.bluetoothOn;
        if (iconName.includes("headset") || iconName.includes("headphones") || iconName.includes("audio"))
            return Icons.headphones;
        if (iconName.includes("phone"))
            return Icons.phone;
        if (iconName.includes("mouse"))
            return Icons.mouse;
        if (iconName.includes("keyboard"))
            return Icons.keyboard;
        if (iconName.includes("computer") || iconName.includes("laptop"))
            return Icons.laptop;
        if (iconName.includes("gaming"))
            return Icons.controller;
        return Icons.bluetoothOn;
    }

    Component.onCompleted: {
        Logger.info("Service initialized");
    }

    onEnabledChanged: {
        Logger.info(`Enabled state changed: ${enabled}`);
        refresh();
    }
}
