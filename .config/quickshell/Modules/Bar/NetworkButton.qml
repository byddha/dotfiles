import QtQuick
import "../../Utils"
import "../../Services"

Rectangle {
    id: networkButton

    width: BarStyle.buttonSize
    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

    Text {
        anchors.centerIn: parent
        text: Icons.network
        font.family: BarStyle.iconFont
        font.pixelSize: BarStyle.iconSize
        color: BarStyle.iconColor
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            Logger.info("Network clicked")
        }
    }

    states: State {
        name: "hovered"
        when: mouseArea.containsMouse
        PropertyChanges {
            target: networkButton
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
