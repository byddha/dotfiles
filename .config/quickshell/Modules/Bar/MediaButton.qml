pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Mpris
import "../../Config"
import "../../Services"

/**
 * MediaButton - The playing track. Hover swaps the artist for previous / play-pause / next and
 * opens the media popout; the wheel switches between players. On a vertical bar it is only
 * the app's icon, and a click plays or pauses.
 */
BarItem {
    id: root

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing

    visible: MprisController.stableHasPlayer && player !== null

    onClicked: mouse => {
        if (vertical && mouse.button === Qt.LeftButton)
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
        implicitWidth: 16
        implicitHeight: 16

        BarAppIcon {
            anchors.fill: parent
            visible: root.playing
            appClass: root.player?.desktopEntry ?? ""
        }
        BarIcon {
            visible: !root.playing
            text: Lucide.pause
            color: Theme.alpha(Theme.textSecondary, 0.66)
        }
    }

    BarText {
        visible: !root.vertical
        width: Math.min(implicitWidth, 260)
        elide: Text.ElideRight
        text: MprisController.stableTrackTitle
    }

    BarText {
        visible: !root.vertical && !root.hovered && text !== ""
        width: Math.min(implicitWidth, 160)
        elide: Text.ElideRight
        role: "secondary"
        text: MprisController.stableTrackArtist ? `· ${MprisController.stableTrackArtist}` : ""
    }

    Row {
        visible: !root.vertical && root.hovered
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

    component Control: Rectangle {
        id: control

        property string glyph

        signal tapped

        implicitWidth: 22
        implicitHeight: 22
        radius: 5
        opacity: enabled ? 1 : 0.4
        color: tap.pressed ? Theme.colLayer3 : hover.hovered ? Theme.alpha(Theme.textColor, 0.08) : "transparent"

        BarIcon {
            anchors.centerIn: parent
            size: 14
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
