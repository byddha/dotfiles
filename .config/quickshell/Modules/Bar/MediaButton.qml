pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Mpris
import "../../Config"
import "../../Services"
import "../../Components"

/**
 * MediaButton - The playing track. Hover swaps the artist for previous / play-pause / next and
 * opens the media popout; the wheel switches between players. On a vertical bar, and at level 3,
 * it is only the app's icon, and a click plays or pauses. Level 1 shortens the title and drops
 * the artist; the controls keep their place.
 */
BarItem {
    id: root

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing

    readonly property bool iconView: vertical || level >= 3
    readonly property int titleCap: level >= 1 ? 190 : 260

    visible: MprisController.stableHasPlayer && player !== null
    iconOnly: iconView && !vertical

    function lengthAt(level) {
        if (vertical)
            return padded(BarLayout.appIconSize);
        if (level >= 3)
            return BarLayout.itemSize;
        const slot = level >= 1 ? controls.implicitWidth : Math.max(artist.implicitCapped, controls.implicitWidth);
        return padded(BarLayout.appIconSize + BarLayout.itemGap + Math.min(title.implicitWidth, level >= 1 ? 190 : 260) + BarLayout.itemGap + slot);
    }

    onClicked: mouse => {
        if (iconView && mouse.button === Qt.LeftButton)
            player.togglePlaying();
    }
    onWheel: wheel => {
        if (wheel.angleDelta.y > 0)
            MprisController.previousPlayer();
        else if (wheel.angleDelta.y < 0)
            MprisController.nextPlayer();
    }

    MediaPopout {
        target: root
        shown: root.hovered
    }

    // Paused: a pause glyph where the app's icon was
    Item {
        implicitWidth: BarLayout.appIconSize
        implicitHeight: BarLayout.appIconSize

        BarAppIcon {
            anchors.fill: parent
            visible: root.playing
            appClass: root.player?.desktopEntry ?? ""
        }
        Icon {
            visible: !root.playing
            text: Lucide.pause
            color: Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
        }
    }

    StyledText {
        id: title

        visible: !root.iconView
        width: Math.min(implicitWidth, root.titleCap)
        elide: Text.ElideRight
        text: MprisController.stableTrackTitle
    }

    // The artist, or on hover the controls, in one slot as wide as the wider of the two:
    // the item keeps its size, so nothing moves out from under the pointer
    Item {
        visible: !root.iconView
        implicitWidth: root.level >= 1 ? controls.implicitWidth : Math.max(artist.implicitCapped, controls.implicitWidth)
        implicitHeight: controls.implicitHeight

        StyledText {
            id: artist

            readonly property real implicitCapped: Math.min(implicitWidth, 160)

            visible: !root.hovered && root.level < 1
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 160)
            elide: Text.ElideRight
            role: "secondary"
            text: MprisController.stableTrackArtist ? `· ${MprisController.stableTrackArtist}` : ""
        }

        Row {
            id: controls

            visible: root.hovered
            spacing: 2

            Control {
                glyph: Lucide.skipBack
                enabled: MprisController.stableCanGoPrevious
                onTapped: root.player.previous()
            }
            Control {
                glyph: root.playing ? Lucide.pause : Lucide.play
                onTapped: root.player.togglePlaying()
            }
            Control {
                glyph: Lucide.skipForward
                enabled: MprisController.stableCanGoNext
                onTapped: root.player.next()
            }
        }
    }

    component Control: Rectangle {
        id: control

        property string glyph

        signal tapped

        implicitWidth: 26
        implicitHeight: 26
        radius: 5
        opacity: enabled ? 1 : 0.4
        color: tap.pressed ? Theme.colLayer3 : hover.hovered ? Theme.alpha(Theme.textColor, 0.08) : "transparent"

        Icon {
            anchors.centerIn: parent
            size: 16
            text: control.glyph
        }

        HoverHandler {
            id: hover
        }
        TapHandler {
            id: tap

            onTapped: control.tapped()
        }
    }
}
