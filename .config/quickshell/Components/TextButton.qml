import QtQuick
import QtQuick.Layouts
import "../Config"

Rectangle {
    id: root

    property string text: ""
    property string icon: ""

    signal clicked

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 32
    radius: Theme.radiusBase
    opacity: enabled ? 1 : Theme.stateDisabled
    color: !enabled ? "transparent" : mouseArea.pressed ? Theme.alpha(Theme.primary, 0.2) : mouseArea.containsMouse ? Theme.alpha(Theme.primary, 0.12) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingBase

        Icon {
            visible: root.icon !== ""
            text: root.icon
            color: Theme.primary
        }

        StyledText {
            text: root.text
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.primary
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
