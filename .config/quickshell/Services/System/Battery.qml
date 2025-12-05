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
    readonly property bool pluggedIn: charging || state === UPowerDeviceState.PendingCharge || full

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

    // Get appropriate icon based on state
    function getIcon(): string {
        if (!available)
            return Icons.batteryAlert;

        if (charging) {
            if (percentage >= 95)
                return Icons.batteryCharging100;
            if (percentage >= 85)
                return Icons.batteryCharging90;
            if (percentage >= 75)
                return Icons.batteryCharging80;
            if (percentage >= 65)
                return Icons.batteryCharging70;
            if (percentage >= 55)
                return Icons.batteryCharging60;
            if (percentage >= 45)
                return Icons.batteryCharging50;
            if (percentage >= 35)
                return Icons.batteryCharging40;
            if (percentage >= 25)
                return Icons.batteryCharging30;
            if (percentage >= 15)
                return Icons.batteryCharging20;
            return Icons.batteryCharging10;
        } else {
            if (percentage >= 95)
                return Icons.battery100;
            if (percentage >= 85)
                return Icons.battery90;
            if (percentage >= 75)
                return Icons.battery80;
            if (percentage >= 65)
                return Icons.battery70;
            if (percentage >= 55)
                return Icons.battery60;
            if (percentage >= 45)
                return Icons.battery50;
            if (percentage >= 35)
                return Icons.battery40;
            if (percentage >= 25)
                return Icons.battery30;
            if (percentage >= 15)
                return Icons.battery20;
            return Icons.battery10;
        }
    }

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
            Quickshell.execDetached(["notify-send", "Low Battery", `Battery at ${percentage}%. Consider plugging in.`, "-u", "normal", "-a", "Battery"]);
            Logger.warn(`Low battery: ${percentage}%`);
        } else if (!isLow) {
            _notifiedLow = false;
        }
    }

    onIsCriticalChanged: {
        if (isCritical && !_notifiedCritical) {
            _notifiedCritical = true;
            Quickshell.execDetached(["notify-send", "Critical Battery", `Battery at ${percentage}%! Plug in now!`, "-u", "critical", "-a", "Battery"]);
            Logger.error(`Critical battery: ${percentage}%`);
        } else if (!isCritical) {
            _notifiedCritical = false;
        }
    }

    Component.onCompleted: {
        Logger.info(available ? `Service initialized: ${percentage}%` : "No battery detected");
    }
}
