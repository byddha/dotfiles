import QtQuick
import "../Config"

Rectangle {
    id: button

    property string icon: ""
    signal clicked

    width: 48
    height: 48
    radius: width / 2
    color: mouseArea.containsMouse ? Theme.colLayer1 : Theme.colLayer0

    scale: mouseArea.containsMouse ? 1.15 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutBack
            easing.overshoot: 2.0
        }
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

    Behavior on color {
        ColorAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }
}
