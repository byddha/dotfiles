pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../Config"
import ".."

/**
 * Peripherals - Unified peripheral device model
 *
 * Merges UPower peripherals, custom script devices, and BlueZ connected devices
 * into a single normalized list for the sidebar Peripherals tab.
 */
Singleton {
    id: root

    property list<var> devices: []

    // Rebuild on any source change, debounced
    Timer {
        id: rebuildTimer
        interval: 200
        onTriggered: root._rebuild()
    }

    function _requestRebuild() {
        rebuildTimer.restart();
    }

    // Watch UPower device changes
    Connections {
        target: UPower.devices
        function onObjectInsertedPost() {
            root._requestRebuild();
        }
        function onObjectRemovedPost() {
            root._requestRebuild();
        }
    }

    // Watch custom device changes
    onCustomDevicesSourceChanged: _requestRebuild()
    property var customDevicesSource: PeripheralBatteries.customDevices

    // Watch BlueZ device changes
    property int _btRefresh: Bluetooth.refreshTrigger
    on_BtRefreshChanged: _requestRebuild()

    // Watch brand/logo resolution
    Connections {
        target: BrandLogoService
        function onBrandResolved() {
            root._requestRebuild();
        }
        function onReadyChanged() {
            root._requestRebuild();
        }
    }

    function _findBlueZMatch(name) {
        if (!name)
            return null;
        const lower = name.toLowerCase();
        const btDevices = Bluetooth.connectedDevices;
        for (let i = 0; i < btDevices.length; i++) {
            const btName = (btDevices[i].name || "").toLowerCase();
            if (btName && (lower.includes(btName) || btName.includes(lower)))
                return btDevices[i];
        }
        return null;
    }

    // The MAC's vendor wins over a brand guessed from the name: a Bluetooth device can be listed
    // before BlueZ reports it, and then only its name is known
    function _resolveBrand(id, name, macSource) {
        const cached = BrandLogoService.getCachedDeviceBrand(id);
        if (macSource) {
            BrandLogoService.lookupBrandFromMac(macSource, function (vendor) {
                if (vendor && vendor !== BrandLogoService.getCachedDeviceBrand(id)) {
                    BrandLogoService.setCachedDeviceBrand(id, vendor);
                    root._requestRebuild();
                }
            });
        }
        if (cached)
            return cached;
        if (!macSource && name) {
            // Custom devices with no MAC — use device name for domain search
            BrandLogoService.setCachedDeviceBrand(id, name);
            return name;
        }

        return "";
    }

    function _entry(id, name, type, mac, connectionType, percentage, charging) {
        const brand = _resolveBrand(id, name, mac);
        return {
            id: id,
            name: name,
            brand: brand,
            logoPath: BrandLogoService.getLogoPath(brand),
            type: type,
            typeIcon: PeripheralBatteries.getIconForType(type),
            connectionType: connectionType,
            percentage: percentage,
            charging: charging
        };
    }

    function _rebuild() {
        if (!BrandLogoService.ready)
            return;
        const result = [];
        const seen = new Set();
        const configDevices = Config.options.peripheralBatteries?.devices ?? [];

        // 1. UPower peripherals
        const upowerDevices = UPower.devices.values;
        for (let i = 0; i < upowerDevices.length; i++) {
            const dev = upowerDevices[i];
            if (!PeripheralBatteries.isPeripheral(dev, configDevices))
                continue;

            const name = dev.model || "Unknown Device";
            const btMatch = _findBlueZMatch(name);
            const charging = dev.state === UPowerDeviceState.Charging;
            const full = dev.state === UPowerDeviceState.FullyCharged;

            const macMatch = (dev.nativePath || "").match(/([0-9a-fA-F]{2}[:\-]){5}[0-9a-fA-F]{2}/);
            const mac = macMatch ? macMatch[0] : (btMatch?.address ?? "");
            const connectionType = btMatch ? "bluetooth" : (charging || full) ? "wired" : "2.4ghz";

            if (btMatch)
                seen.add("bt:" + btMatch.name);
            result.push(_entry("upower:" + name, name, PeripheralBatteries.upowerTypeName(dev.type) || "device", mac, connectionType, Math.round((dev.percentage ?? 0) * 100), charging));
        }

        // 2. Custom script devices
        const customs = PeripheralBatteries.customDevices;
        for (let i = 0; i < customs.length; i++) {
            const dev = customs[i];
            if (!dev || !dev.present)
                continue;

            const name = dev.name || "Device";
            const configEntry = configDevices[i] || {};
            const btMatch = _findBlueZMatch(name);
            const charging = dev.charging ?? false;
            const connectionType = btMatch ? "bluetooth" : charging ? "wired" : "2.4ghz";

            if (btMatch)
                seen.add("bt:" + btMatch.name);
            // Only a BlueZ match can give a custom device a MAC
            result.push(_entry("custom:" + i, name, configEntry.type || "device", btMatch?.address ?? "", connectionType, dev.percentage ?? 0, charging));
        }

        // 3. BlueZ devices with battery that weren't already matched
        const btDevices = Bluetooth.connectedDevices;
        for (let i = 0; i < btDevices.length; i++) {
            const dev = btDevices[i];
            if (!dev.batteryAvailable)
                continue;
            if (seen.has("bt:" + dev.name))
                continue;

            // Infer type from BlueZ icon
            let type = "device";
            const icon = (dev.icon || "").toLowerCase();
            if (icon.includes("headset") || icon.includes("headphones") || icon.includes("audio"))
                type = "headphones";
            else if (icon.includes("mouse"))
                type = "mouse";
            else if (icon.includes("keyboard"))
                type = "keyboard";
            else if (icon.includes("phone"))
                type = "phone";
            else if (icon.includes("gaming"))
                type = "gamepad";

            result.push(_entry("bluez:" + dev.name, dev.name || "Bluetooth Device", type, dev.address ?? "", "bluetooth", Math.round((dev.battery ?? 0) * 100), false));
        }

        root.devices = result;
    }

    Component.onCompleted: _rebuild()
}
