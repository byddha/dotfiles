import QtQuick
import "../Config"

Text {
    id: root

    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    font {
        hintingPreference: Font.PreferFullHinting
        family: Theme.fontFamily
        pixelSize: Theme.fontSizeSmall
    }
    color: Theme.textColor
}
