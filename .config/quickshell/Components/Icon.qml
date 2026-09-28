import QtQuick
import "../Config"

// A Lucide glyph (see Lucide) in a fixed square, so icons never change an item's size
Text {
    property int size: Theme.iconSize

    width: size
    height: size
    color: Theme.textColor
    font.family: Theme.fontIcons
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
