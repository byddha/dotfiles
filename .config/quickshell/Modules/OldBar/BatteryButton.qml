import QtQuick
import "../../Services"

BatteryPill {
    visible: Battery.available
    icon: Battery.getIcon()
    percentage: Battery.percentage
    charging: Battery.charging
    isLow: Battery.isLow
    isCritical: Battery.isCritical
    tooltipText: Battery.getStatusText()
}
