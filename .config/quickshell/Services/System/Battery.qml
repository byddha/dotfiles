pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../Utils"
import ".."

/**
 * Battery - Battery monitoring service using UPower
 *
 * Provides battery state, percentage, charging status, and time estimates.
 */
Singleton {
    id: root

    // Whether a laptop battery is available
    readonly property bool available: UPower.displayDevice?.isLaptopBattery ?? false

    // Battery percentage (0-100)
    readonly property int percentage: available ? Math.round(UPower.displayDevice.percentage * 100) : 0

    // Charging state
    readonly property var state: UPower.displayDevice?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool discharging: state === UPowerDeviceState.Discharging
    readonly property bool full: state === UPowerDeviceState.FullyCharged

    // Time estimates (in seconds)
    readonly property int timeToEmpty: available ? (UPower.displayDevice.timeToEmpty ?? 0) : 0
    readonly property int timeToFull: available ? (UPower.displayDevice.timeToFull ?? 0) : 0

    // Power rate (watts)
    readonly property real powerRate: available ? Math.abs(UPower.displayDevice.changeRate ?? 0) : 0

    // Thresholds
    readonly property int lowThreshold: 20
    readonly property int criticalThreshold: 10

    readonly property bool isLow: available && !charging && percentage <= lowThreshold
    readonly property bool isCritical: available && !charging && percentage <= criticalThreshold

    // Format time as "Xh Ym"
    function formatTime(seconds: int): string {
        if (seconds <= 0)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        if (hours > 0) {
            return `${hours}h ${minutes}m`;
        }
        return `${minutes}m`;
    }

    // Get status text for tooltip
    function getStatusText(): string {
        if (!available)
            return "No battery detected";

        let status = `${percentage}%`;
        if (charging) {
            status += " - Charging";
            if (timeToFull > 0) {
                status += ` (${formatTime(timeToFull)} to full)`;
            }
        } else if (discharging) {
            if (timeToEmpty > 0) {
                status += ` - ${formatTime(timeToEmpty)} remaining`;
            }
        } else if (full) {
            status += " - Fully charged";
        }

        if (powerRate > 0) {
            status += `\n${powerRate.toFixed(1)}W`;
        }

        return status;
    }

    // Low battery notifications
    property bool _notifiedLow: false
    property bool _notifiedCritical: false

    onIsLowChanged: {
        if (isLow && !_notifiedLow) {
            _notifiedLow = true;
            Quickshell.execDetached(["notify-send", "-e", "Low Battery", `Battery at ${percentage}%. Consider plugging in.`, "-u", "normal", "-a", "Battery"]);
            Logger.warn(`Low battery: ${percentage}%`);
        } else if (!isLow) {
            _notifiedLow = false;
        }
    }

    onIsCriticalChanged: {
        if (isCritical && !_notifiedCritical) {
            _notifiedCritical = true;
            Quickshell.execDetached(["notify-send", "-e", "Critical Battery", `Battery at ${percentage}%! Plug in now!`, "-u", "critical", "-a", "Battery"]);
            Logger.error(`Critical battery: ${percentage}%`);
        } else if (!isCritical) {
            _notifiedCritical = false;
        }
    }
}
