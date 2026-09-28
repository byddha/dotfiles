import QtQuick
import "../../Config"
import "../../Services"

BarItem {
    id: root

    readonly property int count: Notifications.list.length

    iconOnly: count === 0
    tooltipTitle: "Notifications"
    tooltipDetail: count === 0 ? "None" : `${count} unread`

    onClicked: mouse => {
        if (mouse.button !== Qt.LeftButton)
            return;
        Settings.sidebarSelectedTab = 1;
        Settings.sidebarVisible = true;
    }

    Item {
        implicitWidth: 16
        implicitHeight: 16

        BarIcon {
            text: Lucide.bell
        }

        // Unread: an accent dot on the bell
        Rectangle {
            visible: root.count > 0
            x: 10
            y: -1
            width: 8
            height: 8
            radius: 4
            color: Theme.primary
            border.width: 2
            border.color: root.hovered ? Theme.colLayer2 : Theme.colLayer0
        }
    }
    BarText {
        visible: root.count > 0
        font.pixelSize: root.vertical ? 11 : 13
        font.weight: root.vertical ? Font.DemiBold : Font.Medium
        text: root.count
    }
}
