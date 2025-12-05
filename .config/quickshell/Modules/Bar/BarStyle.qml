pragma Singleton
import QtQuick
import "../../Config"

QtObject {
    // Button styling
    readonly property int buttonSize: Theme.barHeight
    readonly property color buttonBackground: Theme.colLayer0
    readonly property color buttonBackgroundHover: Theme.alpha(Theme.textColor, 0.1)
    readonly property real buttonRadius: Theme.radiusBase

    // Icon styling
    readonly property string iconFont: Theme.fontFamilyIcons
    readonly property int iconSize: Theme.iconSize
    readonly property color iconColor: Theme.textColor
    readonly property color iconColorMuted: Theme.textSecondary

    // Text styling
    readonly property string textFont: Theme.fontFamily
    readonly property int textSize: Theme.fontSizeBase
    readonly property int textWeight: Font.Black
    readonly property color textColor: Theme.textColor
    readonly property color textSecondaryColor: Theme.textSecondary

    // Layout
    readonly property int spacing: Theme.spacingBase
    readonly property int spacingLarge: Theme.spacingLarge

    // Bar dimensions
    readonly property int barHeight: Theme.barHeight
    readonly property int barMargin: Theme.spacingBase
    readonly property color barBackground: "transparent"
}
