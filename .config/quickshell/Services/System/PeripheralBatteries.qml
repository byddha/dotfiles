pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../Utils"
import ".."

/**
 * PeripheralBatteries - Battery monitoring for peripheral UPower devices
 *
 * Tracks non-laptop battery devices (trackpad, mouse, keyboard, headset, etc.)
 * with per-device low/critical notifications.
 */
Singleton {
    id: root

    readonly property int lowThreshold: 20
    readonly property int criticalThreshold: 10

    function isPeripheral(device): bool {
        if (!device || !device.isPresent)
            return false;
        if (device.isLaptopBattery)
            return false;
        if (device.type === UPowerDeviceType.LinePower)
            return false;
        return true;
    }

    function getDeviceIcon(device): string {
        if (!device)
            return Icons.device;

        switch (device.type) {
        case UPowerDeviceType.Touchpad:
            return Icons.trackpad;
        case UPowerDeviceType.Mouse:
            return Icons.mouse;
        case UPowerDeviceType.Keyboard:
            return Icons.keyboard;
        case UPowerDeviceType.Headphones:
            return Icons.headphones;
        case UPowerDeviceType.Headset:
            return Icons.headset;
        case UPowerDeviceType.Speakers:
            return Icons.speaker;
        case UPowerDeviceType.GamingInput:
            return Icons.controller;
        case UPowerDeviceType.Phone:
            return Icons.phone;
        default:
            return Icons.device;
        }
    }

    function getDeviceLabel(device): string {
        if (!device)
            return "Device";
        return device.model || UPowerDeviceType.toString(device.type) || "Device";
    }

    function getDeviceStatusText(device): string {
        if (!device)
            return "Unknown device";

        const pct = Math.round((device.percentage ?? 0) * 100);
        const label = getDeviceLabel(device);
        const charging = device.state === UPowerDeviceState.Charging;
        const full = device.state === UPowerDeviceState.FullyCharged;

        let status = `${label}: ${pct}%`;
        if (charging)
            status += " - Charging";
        else if (full)
            status += " - Fully charged";

        return status;
    }

    // Per-device notification tracking via Instantiator
    Instantiator {
        model: UPower.devices
        delegate: QtObject {
            required property var modelData

            property bool isPeripheral: root.isPeripheral(modelData)
            property int percentage: Math.round((modelData?.percentage ?? 0) * 100)
            property bool charging: modelData?.state === UPowerDeviceState.Charging
            property bool isLow: isPeripheral && !charging && percentage <= root.lowThreshold
            property bool isCritical: isPeripheral && !charging && percentage <= root.criticalThreshold

            property bool _notifiedLow: false
            property bool _notifiedCritical: false

            onIsLowChanged: {
                if (isLow && !_notifiedLow) {
                    _notifiedLow = true;
                    const label = root.getDeviceLabel(modelData);
                    Quickshell.execDetached(["notify-send", `Low Battery: ${label}`, `${label} at ${percentage}%. Consider charging.`, "-u", "normal", "-a", "Battery"]);
                    Logger.warn(`Low peripheral battery: ${label} at ${percentage}%`);
                } else if (!isLow) {
                    _notifiedLow = false;
                }
            }

            onIsCriticalChanged: {
                if (isCritical && !_notifiedCritical) {
                    _notifiedCritical = true;
                    const label = root.getDeviceLabel(modelData);
                    Quickshell.execDetached(["notify-send", `Critical Battery: ${label}`, `${label} at ${percentage}%! Charge now!`, "-u", "critical", "-a", "Battery"]);
                    Logger.error(`Critical peripheral battery: ${label} at ${percentage}%`);
                } else if (!isCritical) {
                    _notifiedCritical = false;
                }
            }
        }
    }

    Component.onCompleted: {
        Logger.info("Service initialized");
    }
}
