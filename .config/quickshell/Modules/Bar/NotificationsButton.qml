import QtQuick
import "../../Config"
import "../../Services"
import "../../Components"

BarItem {
    id: root

    readonly property int count: Notifications.list.length

    iconOnly: count === 0 || (!vertical && level >= 3)

    function lengthAt(level) {
        if (vertical)
            return padded(Theme.iconSize + (count > 0 && level < 3 ? BarLayout.itemGap + countText.implicitHeight : 0));
        return count === 0 || level >= 3 ? BarLayout.itemSize : padded(Theme.iconSize + BarLayout.itemGap + countText.implicitWidth);
    }
    tooltipTitle: "Notifications"
    tooltipDetail: count === 0 ? "None" : `${count} unread`

    onClicked: mouse => {
        if (mouse.button !== Qt.LeftButton)
            return;
        Settings.toggleSidebarTab(1);
    }

    Item {
        implicitWidth: Theme.iconSize
        implicitHeight: Theme.iconSize

        Icon {
            text: Lucide.bell
        }

        // Unread: an accent dot on the bell
        Rectangle {
            visible: root.count > 0
            x: parent.width - width + 3
            y: -2
            width: BarLayout.dotSize + 4
            height: width
            radius: width / 2
            color: Theme.primary
            border.width: 2
            border.color: root.hovered ? Theme.chipSurface : Theme.hostSurface
        }
    }
    StyledText {
        id: countText

        visible: root.count > 0 && root.level < 3
        font.pixelSize: root.vertical ? Theme.fontSizeTiny : Theme.fontSizeBase
        font.weight: root.vertical ? Font.DemiBold : Font.Medium
        text: root.count
    }
}
