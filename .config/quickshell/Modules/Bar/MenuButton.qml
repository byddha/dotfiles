import QtQuick
import "../../Utils"
import "../../Services"

Rectangle {
    id: menuButton

    width: BarStyle.buttonSize
    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

    Text {
        anchors.centerIn: parent
        text: Icons.menu
        font.family: BarStyle.textFont
        font.pixelSize: BarStyle.textSize
        color: BarStyle.iconColor
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            Logger.info("Menu clicked")
        }
    }

    states: State {
        name: "hovered"
        when: mouseArea.containsMouse
        PropertyChanges {
            target: menuButton
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
