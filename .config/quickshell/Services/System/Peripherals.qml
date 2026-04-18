pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../Config"
import "../../Utils"
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
    }

    readonly property var _upowerTypeMap: ({
            [UPowerDeviceType.Touchpad]: "trackpad",
            [UPowerDeviceType.Mouse]: "mouse",
            [UPowerDeviceType.Keyboard]: "keyboard",
            [UPowerDeviceType.Headphones]: "headphones",
            [UPowerDeviceType.Headset]: "headset",
            [UPowerDeviceType.Speakers]: "speakers",
            [UPowerDeviceType.GamingInput]: "gamepad",
            [UPowerDeviceType.Phone]: "phone"
        })

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

    function _resolveBrand(id, name, macSource) {
        const cached = BrandLogoService.getCachedDeviceBrand(id);
        if (cached)
            return cached;

        if (macSource) {
            BrandLogoService.lookupBrandFromMac(macSource, function (vendor) {
                if (vendor && !BrandLogoService.getCachedDeviceBrand(id)) {
                    BrandLogoService.setCachedDeviceBrand(id, vendor);
                    root._requestRebuild();
                }
            });
        } else if (name) {
            // Custom devices with no MAC — use device name for domain search
            BrandLogoService.setCachedDeviceBrand(id, name);
            return name;
        }

        return "";
    }

    function _rebuild() {
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
            const type = _upowerTypeMap[dev.type] || "device";
            const btMatch = _findBlueZMatch(name);
            const charging = dev.state === UPowerDeviceState.Charging;
            const full = dev.state === UPowerDeviceState.FullyCharged;
            const id = "upower:" + name;

            const macMatch = (dev.nativePath || "").match(/([0-9a-fA-F]{2}[:\-]){5}[0-9a-fA-F]{2}/);
            const mac = macMatch ? macMatch[0] : (btMatch?.address ?? "");
            const brand = _resolveBrand(id, name, mac);

            let connectionType = "unknown";
            if (btMatch)
                connectionType = "bluetooth";
            else if (charging || full)
                connectionType = "wired";
            else
                connectionType = "2.4ghz";

            seen.add(btMatch ? ("bt:" + btMatch.name) : "");

            result.push({
                id: id,
                name: name,
                brand: brand,
                logoPath: BrandLogoService.getLogoPath(brand),
                type: type,
                typeIcon: PeripheralBatteries.getIconForType(type),
                connectionType: connectionType,
                percentage: Math.round((dev.percentage ?? 0) * 100),
                charging: charging
            });
        }

        // 2. Custom script devices
        const customs = PeripheralBatteries.customDevices;
        for (let i = 0; i < customs.length; i++) {
            const dev = customs[i];
            if (!dev || !dev.present)
                continue;

            const name = dev.name || "Device";
            const configEntry = configDevices[i] || {};
            const type = configEntry.type || "device";
            const btMatch = _findBlueZMatch(name);
            const id = "custom:" + i;

            // Try BlueZ match for MAC
            const mac = btMatch?.address ?? "";
            const brand = _resolveBrand(id, name, mac);

            const charging = dev.charging ?? false;
            let connectionType = "unknown";
            if (btMatch)
                connectionType = "bluetooth";
            else if (charging)
                connectionType = "wired";
            else
                connectionType = "2.4ghz";

            seen.add(btMatch ? ("bt:" + btMatch.name) : "");

            result.push({
                id: id,
                name: name,
                brand: brand,
                logoPath: BrandLogoService.getLogoPath(brand),
                type: type,
                typeIcon: PeripheralBatteries.getIconForType(type),
                connectionType: connectionType,
                percentage: dev.percentage ?? 0,
                charging: charging
            });
        }

        // 3. BlueZ devices with battery that weren't already matched
        const btDevices = Bluetooth.connectedDevices;
        for (let i = 0; i < btDevices.length; i++) {
            const dev = btDevices[i];
            if (!dev.batteryAvailable)
                continue;
            if (seen.has("bt:" + dev.name))
                continue;

            const name = dev.name || "Bluetooth Device";
            const id = "bluez:" + dev.name;
            const mac = dev.address ?? "";
            const brand = _resolveBrand(id, name, mac);

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

            result.push({
                id: id,
                name: name,
                brand: brand,
                logoPath: BrandLogoService.getLogoPath(brand),
                type: type,
                typeIcon: PeripheralBatteries.getIconForType(type),
                connectionType: "bluetooth",
                percentage: Math.round((dev.battery ?? 0) * 100),
                charging: false
            });
        }

        Logger.debug(`Peripherals rebuilt: ${result.length} devices`);
        root.devices = result;
    }

    Component.onCompleted: {
        Logger.info("Peripherals service initialized");
        _rebuild();
    }
}
