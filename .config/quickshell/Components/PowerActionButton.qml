import QtQuick
import "../Config"

Rectangle {
    id: button

    property string icon: ""
    signal clicked()

    width: 48
    height: 48
    radius: width / 2
    color: mouseArea.containsMouse ? Theme.colLayer1 : Theme.colLayer0

    transform: Scale {
        id: buttonScale
        origin.x: button.width / 2
        origin.y: button.height / 2
        xScale: 1.0
        yScale: 1.0
    }

    Text {
        anchors.centerIn: parent
        text: button.icon
        font.family: Theme.fontFamilyIcons
        font.pixelSize: 24
        color: mouseArea.containsMouse ? Theme.primary : Theme.textColor
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }

    states: State {
        name: "hovered"
        when: mouseArea.containsMouse
        PropertyChanges {
            target: buttonScale
            xScale: 1.15
            yScale: 1.15
        }
    }

    transitions: Transition {
        NumberAnimation {
            properties: "xScale,yScale"
            duration: 150
            easing.type: Easing.OutBack
            easing.overshoot: 2.0
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }
}
