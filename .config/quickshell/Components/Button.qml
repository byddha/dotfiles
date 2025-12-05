import QtQuick
import QtQuick.Controls
import "../Config"

Button {
    id: root

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeBase

    contentItem: Text {
        text: root.text
        font: root.font
        color: root.down ? Theme.textColor : Theme.textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        visible: text !== ""

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    background: Rectangle {
        implicitWidth: 60
        implicitHeight: 28
        radius: Theme.radiusBase
        color: root.down ? Theme.colLayer0 : Theme.colLayer1
        border.color: root.hovered ? Theme.primary : Theme.alpha(Theme.textColor, 0.2)
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }
}
