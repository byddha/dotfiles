import QtQuick
import "../../Config"

// Every number in the bar uses tabular figures, so counters and the clock never shift the layout
Text {
    // "primary", "secondary" or "tertiary"
    property string role: "primary"

    color: role === "secondary" ? Theme.alpha(Theme.textSecondary, BarLayout.secondaryOpacity) : role === "tertiary" ? Theme.alpha(Theme.textSecondary, BarLayout.tertiaryOpacity) : Theme.textColor
    font.family: Theme.fontUi
    font.pixelSize: BarLayout.textSize
    font.weight: role === "primary" ? Font.Medium : Font.Normal
    font.features: {
        "tnum": 1
    }
    verticalAlignment: Text.AlignVCenter
}
