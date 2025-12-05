import QtQuick
import "../Config"

Text {
    id: root

    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    font {
        hintingPreference: Font.PreferFullHinting
        family: Theme?.fontFamily ?? "sans-serif"
        pixelSize: Theme?.fontSizeSmall ?? 12
    }
    color: Theme?.textColor ?? "white"
}
