import QtQuick
import "../Config"

Rectangle {
    id: root

    property string icon: ""
    property int iconSize: 16
    property bool toggled: false
    property bool danger: false
    property color iconColor: danger ? Theme.accentRed : toggled ? Theme.primary : Theme.textSecondary

    signal clicked
    signal rightClicked

    implicitWidth: 32
    implicitHeight: 32
    radius: Theme.radiusBase
    color: toggled ? Theme.alpha(Theme.primary, Theme.stateSelected) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    StateLayer {
        hovered: mouseArea.containsMouse
        pressed: mouseArea.pressed
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.fontFamilyGlyphs
        font.pixelSize: root.iconSize
        color: root.iconColor

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
