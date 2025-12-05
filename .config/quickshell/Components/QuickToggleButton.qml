import QtQuick
import "../Config"

Rectangle {
    id: root

    property string icon: ""
    property string iconOff: ""
    property string label: ""
    property bool isStateful: false
    property bool isActive: false
    property int iconSize: 24

    signal clicked()

    width: 56
    height: 56
    radius: Theme.radiusBase
    color: isStateful && isActive ? Theme.primary : Theme.colLayer1

    Tooltip {
        id: tooltip
        target: root
        text: root.label
    }

    Text {
        anchors.centerIn: parent
        text: root.isStateful && !root.isActive && root.iconOff ? root.iconOff : root.icon
        font.family: Theme.fontFamilyIcons
        font.pixelSize: root.iconSize
        color: root.isStateful && root.isActive ? Theme.primaryText : Theme.textColor
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: tooltip.show()
        onExited: tooltip.hide()

        onClicked: {
            tooltip.hide()
            root.clicked()
        }
    }

    states: State {
        name: "hovered"
        when: mouseArea.containsMouse
        PropertyChanges {
            target: root
            color: root.isStateful && root.isActive ? Theme.primary : Theme.colLayer2
        }
    }

    transitions: Transition {
        ColorAnimation { duration: 150 }
    }
}
