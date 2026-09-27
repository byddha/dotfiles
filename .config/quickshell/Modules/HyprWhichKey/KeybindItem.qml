import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Services"

Row {
    id: keybindItem

    property var bind
    property int columnWidth: 100

    spacing: 4

    readonly property var parsedDesc: HyprWhichKeyService.parseDescription(bind?.description || bind?.dispatcher + (bind?.arg ? `: ${bind?.arg}` : ""))

    Text {
        text: HyprWhichKeyService.getRawKey(bind)
        font.family: Theme.fontFamily
        font.pixelSize: Config.options.hyprWhichKey.fontSize
        color: Theme.primary
        anchors.verticalCenter: parent.verticalCenter
        width: columnWidth
        horizontalAlignment: Text.AlignRight
    }

    Text {
        text: "→"
        font.family: Theme.fontFamily
        font.pixelSize: Config.options.hyprWhichKey.fontSize
        color: Theme.textSecondary
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: 8
        rightPadding: 4
    }

    Text {
        visible: parsedDesc.glyph !== ""
        text: parsedDesc.glyph
        font.family: Theme.fontFamily
        font.pixelSize: Config.options.hyprWhichKey.fontSize
        font.weight: Font.Bold
        color: ThemeService.base08
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: parsedDesc.text
        font.family: Theme.fontFamily
        font.pixelSize: Config.options.hyprWhichKey.fontSize
        color: {
            if (bind?.dispatcher === "submap")
                return Theme.colSecondary;
            return parsedDesc.text ? ThemeService.base09 : Theme.textSecondary;
        }
        anchors.verticalCenter: parent.verticalCenter
    }
}
