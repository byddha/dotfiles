import QtQuick
import "../../Config"
import "../../Services"

BarItem {
    id: root

    readonly property color tint: Battery.isCritical ? Theme.accentRed : Battery.isLow ? Theme.accentOrange : Theme.textColor

    visible: Battery.available
    fill: Battery.isCritical ? Theme.alpha(Theme.accentRed, 0.16) : "transparent"
    hoverFill: Battery.isCritical ? Theme.alpha(Theme.accentRed, 0.26) : Theme.colLayer2
    tooltipTitle: `Battery ${Battery.percentage}%`
    tooltipDetail: Battery.getStatusText()

    BarIcon {
        text: Battery.charging ? Lucide.batteryCharging : Battery.isCritical ? Lucide.batteryWarning : Battery.percentage >= 80 ? Lucide.batteryFull : Battery.percentage >= 40 ? Lucide.batteryMedium : Lucide.batteryLow
        color: Battery.charging ? Theme.accentGreen : root.tint
    }
    BarText {
        font.pixelSize: root.vertical ? 11 : 13
        font.weight: root.vertical ? Font.DemiBold : Font.Medium
        color: root.tint
        text: root.vertical ? Battery.percentage : `${Battery.percentage}%`
    }
}
