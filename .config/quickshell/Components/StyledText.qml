import QtQuick
import "../Config"

// Every number uses tabular figures, so counters and clocks never shift the layout
Text {
    // "primary", "secondary" or "tertiary"
    property string role: "primary"

    color: role === "secondary" ? Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity) : role === "tertiary" ? Theme.alpha(Theme.textSecondary, Theme.tertiaryOpacity) : Theme.textColor
    font.family: Theme.fontUi
    font.pixelSize: Theme.fontSizeBase
    font.weight: role === "primary" ? Font.Medium : Font.Normal
    font.features: {
        "tnum": 1
    }
    verticalAlignment: Text.AlignVCenter
}
