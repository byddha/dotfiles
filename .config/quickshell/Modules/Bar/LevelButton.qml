import QtQuick
import "../../Config"

/**
 * LevelButton - A level with its mute state (volume, microphone). Wheel changes the level,
 * right click mutes, left click opens the audio panel in the sidebar.
 */
BarItem {
    id: root

    property string name
    property string glyph
    property string mutedGlyph
    property real level
    property bool muted
    property string deviceLabel
    property string device

    readonly property int percent: Math.round(level * 100)

    signal toggleMute
    signal raise
    signal lower

    fill: muted ? Theme.alpha(Theme.accentRed, 0.16) : "transparent"
    hoverFill: muted ? Theme.alpha(Theme.accentRed, 0.26) : Theme.colLayer2
    tooltipTitle: muted ? `${name} muted` : `${name} ${percent}%`
    tooltipDetail: `Scroll to adjust · Right-click to ${muted ? "unmute" : "mute"}` + (device ? `\n${deviceLabel}: ${device}` : "")

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            toggleMute();
        } else if (mouse.button === Qt.LeftButton) {
            Settings.sidebarSelectedTab = 0;
            Settings.sidebarVisible = true;
        }
    }
    onWheel: wheel => {
        if (wheel.angleDelta.y > 0)
            raise();
        else if (wheel.angleDelta.y < 0)
            lower();
    }

    BarIcon {
        text: root.muted ? root.mutedGlyph : root.glyph
        color: root.muted ? Theme.accentRed : Theme.textColor
    }

    // Horizontal: "48%" with a small percent sign, or "Muted"
    Item {
        visible: !root.vertical
        implicitWidth: root.muted ? mutedLabel.implicitWidth : value.implicitWidth + 1 + sign.implicitWidth
        implicitHeight: value.implicitHeight

        BarText {
            id: mutedLabel

            visible: root.muted
            text: "Muted"
        }
        BarText {
            id: value

            visible: !root.muted
            text: root.percent
        }
        BarText {
            id: sign

            visible: !root.muted
            x: value.implicitWidth + 1
            anchors.baseline: value.baseline
            role: "secondary"
            font.pixelSize: 11
            color: Theme.alpha(Theme.textSecondary, 0.55)
            text: "%"
        }
    }

    // Vertical: the number as a caption under the icon
    BarText {
        visible: root.vertical && !root.muted
        font.pixelSize: 11
        font.weight: Font.DemiBold
        text: root.percent
    }
}
