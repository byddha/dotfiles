import QtQuick
import "../Config"
import "../Services"

// Busy indicator for an action the shell started but is still waiting on
Text {
    id: root

    property bool running: visible

    text: Icons.loading
    font.family: Theme.fontFamilyGlyphs
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
        running: root.running
    }
}
