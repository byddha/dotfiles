import QtQuick
import "../../Config"
import "../../Services"

BarPill {
    id: notificationButton

    readonly property int notificationCount: Notifications.list.length

    width: BarStyle.buttonSize
    onClicked: {
        Settings.sidebarSelectedTab = 1;
        Settings.sidebarVisible = true;
    }

    Text {
        anchors.centerIn: parent
        text: Icons.bell
        font.family: BarStyle.iconFont
        font.pixelSize: BarStyle.iconSize
        color: BarStyle.iconColor
    }

    // Count badge
    Rectangle {
        visible: notificationButton.notificationCount > 0
        anchors {
            top: parent.top
            right: parent.right
            topMargin: -1
            rightMargin: -1
        }
        width: Math.max(14, countText.width + 4)
        height: 14
        radius: 5
        color: Theme.primary
        border.width: 1
        border.color: Theme.colLayer0

        Text {
            id: countText
            anchors.centerIn: parent
            font.pixelSize: 8
            font.weight: Font.Bold
            color: Theme.primaryText
            text: notificationButton.notificationCount
        }
    }
}
