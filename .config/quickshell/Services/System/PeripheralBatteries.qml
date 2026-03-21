pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../../Config"
import "../../Utils"
import ".."

/**
 * PeripheralBatteries - Battery monitoring for peripheral devices
 *
 * Combines UPower peripherals with config-driven custom battery sources.
 * Custom devices can replace broken UPower entries or add devices UPower doesn't track.
 */
Singleton {
    id: root

    readonly property int lowThreshold: 20
    readonly property int criticalThreshold: 10

    // Custom device state for the UI — rebuilt on each poll
    property var customDevices: []

    function _isReplaced(device): bool {
        if (!device?.model)
            return false;
        const devices = Config.options.peripheralBatteries?.devices ?? [];
        const modelName = device.model.toLowerCase();
        for (const d of devices) {
            if (d.replaces && modelName.includes(d.replaces.toLowerCase()))
                return true;
        }
        return false;
    }

    function isPeripheral(device): bool {
        if (!device || !device.isPresent)
            return false;
        if (device.isLaptopBattery)
            return false;
        if (device.type === UPowerDeviceType.LinePower)
            return false;
        if (_isReplaced(device))
            return false;
        return true;
    }

    function getIconForType(type: string): string {
        switch (type) {
        case "trackpad":
            return Icons.trackpad;
        case "mouse":
            return Icons.mouse;
        case "keyboard":
            return Icons.keyboard;
        case "headphones":
            return Icons.headphones;
        case "headset":
            return Icons.headset;
        case "speakers":
            return Icons.speaker;
        case "gamepad":
            return Icons.controller;
        case "phone":
            return Icons.phone;
        default:
            return Icons.device;
        }
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

    function _updateCustomDevice(index, name, icon, percentage, charging, present) {
        let devices = customDevices.slice();
        // Ensure array is big enough
        while (devices.length <= index)
            devices.push(null);
        devices[index] = {
            name,
            icon,
            percentage,
            charging,
            present
        };
        customDevices = devices;
    }

    // Emitted after hidraw changes settle — custom device delegates connect to this
    signal repollRequested()

    // Watch for hidraw device changes (plug/unplug/connect/disconnect)
    Process {
        id: hidrawMonitor
        running: true
        command: ["udevadm", "monitor", "--subsystem-match=hidraw", "--udev"]
        stdout: SplitParser {
            onRead: hidrawDebounce.restart()
        }
    }

    Timer {
        id: hidrawDebounce
        interval: 2000
        onTriggered: root.repollRequested()
    }

    // Custom device polling via config
    Instantiator {
        model: Config.options.peripheralBatteries?.devices ?? []

        delegate: QtObject {
            id: customDelegate
            required property var modelData
            required property int index

            property string deviceName: modelData.name ?? "Device"
            property string deviceIcon: root.getIconForType(modelData.type ?? "")
            property int pollInterval: (modelData.interval ?? 30) * 1000

            property int percentage: 0
            property bool charging: false
            property bool present: false

            property bool isLow: present && !charging && percentage <= root.lowThreshold
            property bool isCritical: present && !charging && percentage <= root.criticalThreshold
            property bool _notifiedLow: false
            property bool _notifiedCritical: false

            property var _timer: Timer {
                interval: customDelegate.pollInterval
                running: true
                repeat: true
                onTriggered: pollProc.running = true
            }

            property var _process: Process {
                id: pollProc
                command: ["bash", "-c", customDelegate.modelData.command ?? ""]
                stdout: StdioCollector {
                    id: collector
                    onStreamFinished: {
                        try {
                            const data = JSON.parse(collector.text.trim());
                            customDelegate.percentage = data.percentage ?? 0;
                            customDelegate.charging = data.charging ?? false;
                            customDelegate.present = true;
                        } catch (e) {
                            customDelegate.present = false;
                        }
                        root._updateCustomDevice(customDelegate.index, customDelegate.deviceName, customDelegate.deviceIcon, customDelegate.percentage, customDelegate.charging, customDelegate.present);
                    }
                }
                onExited: (code, status) => {
                    if (code !== 0) {
                        customDelegate.present = false;
                        root._updateCustomDevice(customDelegate.index, customDelegate.deviceName, customDelegate.deviceIcon, 0, false, false);
                    }
                }
            }

            onIsLowChanged: {
                if (isLow && !_notifiedLow) {
                    _notifiedLow = true;
                    Quickshell.execDetached(["notify-send", `Low Battery: ${deviceName}`, `${deviceName} at ${percentage}%. Consider charging.`, "-u", "normal", "-a", "Battery"]);
                    Logger.warn(`Low peripheral battery: ${deviceName} at ${percentage}%`);
                } else if (!isLow) {
                    _notifiedLow = false;
                }
            }

            onIsCriticalChanged: {
                if (isCritical && !_notifiedCritical) {
                    _notifiedCritical = true;
                    Quickshell.execDetached(["notify-send", `Critical Battery: ${deviceName}`, `${deviceName} at ${percentage}%! Charge now!`, "-u", "critical", "-a", "Battery"]);
                    Logger.error(`Critical peripheral battery: ${deviceName} at ${percentage}%`);
                } else if (!isCritical) {
                    _notifiedCritical = false;
                }
            }

            property var _repollConnection: Connections {
                target: root
                function onRepollRequested() {
                    pollProc.running = true;
                }
            }

            Component.onCompleted: {
                root._updateCustomDevice(index, deviceName, deviceIcon, 0, false, false);
                pollProc.running = true;
            }
        }
    }

    // UPower per-device notification tracking
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
