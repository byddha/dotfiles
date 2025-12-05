import QtQuick
import "../../Config"
import "../../Services"
import "../../Utils"

Rectangle {
    id: notificationButton

    readonly property int notificationCount: Notifications.list.length

    width: BarStyle.buttonSize
    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

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

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Settings.sidebarSelectedTab = 1;
            Settings.sidebarVisible = true;
            Logger.info("Opening notifications sidebar");
        }
    }

    states: State {
        name: "hovered"
        when: mouseArea.containsMouse
        PropertyChanges {
            target: notificationButton
            color: BarStyle.buttonBackgroundHover
        }
    }

    transitions: Transition {
        ColorAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }
}
