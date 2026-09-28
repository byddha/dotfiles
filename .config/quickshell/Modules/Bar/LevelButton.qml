import QtQuick
import "../../Config"
import "../../Components"

/**
 * LevelButton - A level with its mute state (volume, microphone). Wheel changes the level,
 * right click mutes, left click opens the audio panel in the sidebar.
 */
BarItem {
    id: root

    property string name
    property string glyph
    property string mutedGlyph
    property real amount
    property bool muted
    property string deviceLabel
    property string device

    readonly property int percent: Math.round(amount * 100)

    signal toggleMute
    signal raise
    signal lower

    fill: muted ? Theme.alpha(Theme.accentRed, 0.16) : "transparent"
    hoverFill: muted ? Theme.alpha(Theme.accentRed, 0.26) : Theme.chipSurface
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

    iconOnly: !vertical && level >= 3

    function lengthAt(level) {
        if (vertical)
            return padded(Theme.iconSize + (level < 3 && !muted ? BarLayout.itemGap + caption.implicitHeight : 0));
        if (level >= 3)
            return BarLayout.itemSize;
        const text = muted ? mutedLabel.implicitWidth : value.implicitWidth + (level < 2 ? 1 + sign.implicitWidth : 0);
        return padded(Theme.iconSize + BarLayout.itemGap + text);
    }

    Icon {
        text: root.muted ? root.mutedGlyph : root.glyph
        color: root.muted ? Theme.accentRed : Theme.textColor
    }

    // Horizontal: "48%" with a small percent sign, or "Muted"
    Item {
        visible: !root.vertical && root.level < 3
        implicitWidth: root.muted ? mutedLabel.implicitWidth : value.implicitWidth + (sign.visible ? 1 + sign.implicitWidth : 0)
        implicitHeight: value.implicitHeight

        StyledText {
            id: mutedLabel

            visible: root.muted
            text: "Muted"
        }
        StyledText {
            id: value

            visible: !root.muted
            text: root.percent
        }
        StyledText {
            id: sign

            visible: !root.muted && root.level < 2
            x: value.implicitWidth + 1
            anchors.baseline: value.baseline
            role: "secondary"
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.alpha(Theme.textSecondary, BarLayout.percentOpacity)
            text: "%"
        }
    }

    // Vertical: the number as a caption under the icon
    StyledText {
        id: caption

        visible: root.vertical && !root.muted && root.level < 3
        font.pixelSize: Theme.fontSizeTiny
        font.weight: Font.DemiBold
        text: root.percent
    }
}
