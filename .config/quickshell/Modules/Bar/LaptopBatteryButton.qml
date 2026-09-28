import QtQuick
import "../../Config"
import "../../Services"

BarItem {
    id: root

    readonly property color tint: Battery.isCritical ? Theme.accentRed : Battery.isLow ? Theme.accentOrange : Theme.textColor

    visible: Battery.available
    iconOnly: !vertical && level >= 3

    function lengthAt(level) {
        if (vertical)
            return padded(16 + (level < 3 ? 4 + value.implicitHeight : 0));
        return level >= 3 ? BarLayout.itemSize : padded(16 + 6 + value.implicitWidth + (level < 2 ? sign.implicitWidth : 0));
    }
    fill: Battery.isCritical ? Theme.alpha(Theme.accentRed, 0.16) : "transparent"
    hoverFill: Battery.isCritical ? Theme.alpha(Theme.accentRed, 0.26) : Theme.colLayer2
    tooltipTitle: `Battery ${Battery.percentage}%`
    tooltipDetail: Battery.getStatusText()

    BarIcon {
        text: Battery.charging ? Lucide.batteryCharging : Battery.isCritical ? Lucide.batteryWarning : Battery.percentage >= 80 ? Lucide.batteryFull : Battery.percentage >= 40 ? Lucide.batteryMedium : Lucide.batteryLow
        color: Battery.charging ? Theme.accentGreen : root.tint
    }
    Row {
        visible: root.level < 3

        BarText {
            id: value

            font.pixelSize: root.vertical ? 11 : 13
            font.weight: root.vertical ? Font.DemiBold : Font.Medium
            color: root.tint
            text: Battery.percentage
        }
        BarText {
            id: sign

            visible: !root.vertical && root.level < 2
            font.pixelSize: 13
            color: root.tint
            text: "%"
        }
    }
}
