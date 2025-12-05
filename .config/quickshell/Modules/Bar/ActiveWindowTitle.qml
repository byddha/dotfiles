import QtQuick
import "../../Config"
import "../../Services"
import "../../Services" as Services

Rectangle {
    id: activeWindowTitle

    width: contentRow.implicitWidth + BarStyle.spacing * 2
    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2

        Text {
            id: iconText
            text: Services.AppIcons.getIcon(Compositor.activeWindowClass, Compositor.activeWindow)
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.iconSize
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: titleText
            text: Services.AppIcons.getDisplayName(Compositor.activeWindowClass, Compositor.activeWindow)
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: BarStyle.textColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    states: State {
        name: "hovered"
        when: mouseArea.containsMouse
        PropertyChanges {
            target: activeWindowTitle
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
