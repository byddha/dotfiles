import QtQuick
import "../../Config"
import "../../Services"
import "../../Components"

BarItem {
    id: root

    property BatteryPopout popout: BatteryPopout {}

    readonly property color tint: Battery.isCritical ? Theme.accentRed : Battery.isLow ? Theme.accentOrange : Theme.textColor

    visible: Battery.available
    iconOnly: !vertical && level >= 3

    function lengthAt(level) {
        if (vertical)
            return padded(Theme.iconSize + (level < 3 ? BarLayout.itemGap + value.implicitHeight : 0));
        return level >= 3 ? BarLayout.itemSize : padded(Theme.iconSize + BarLayout.itemGap + value.implicitWidth + (level < 2 ? sign.implicitWidth : 0));
    }
    fill: Battery.isCritical ? Theme.alpha(Theme.accentRed, 0.16) : "transparent"
    hoverFill: Battery.isCritical ? Theme.alpha(Theme.accentRed, 0.26) : Theme.chipSurface
    highlighted: popout.visible
    tooltipTitle: popout.visible ? "" : `Battery ${Battery.percentage}%`
    tooltipDetail: `${Battery.getStatusText()}\n${PowerMode.name(PowerMode.profile)} profile · Click for details`

    onClicked: mouse => {
        if (mouse.button !== Qt.LeftButton)
            return;
        if (popout.visible)
            popout.hidePanel();
        else
            popout.openFrom(root);
    }

    Icon {
        text: Battery.charging ? Lucide.batteryCharging : Battery.isCritical ? Lucide.batteryWarning : Battery.percentage >= 80 ? Lucide.batteryFull : Battery.percentage >= 40 ? Lucide.batteryMedium : Lucide.batteryLow
        color: Battery.charging ? Theme.accentGreen : root.tint
    }
    Row {
        visible: root.level < 3

        StyledText {
            id: value

            font.pixelSize: root.vertical ? Theme.fontSizeTiny : Theme.fontSizeBase
            font.weight: root.vertical ? Font.DemiBold : Font.Medium
            color: root.tint
            text: Battery.percentage
        }
        StyledText {
            id: sign

            visible: !root.vertical && root.level < 2
            font.pixelSize: Theme.fontSizeTiny
            color: root.tint
            text: "%"
        }
    }
}
