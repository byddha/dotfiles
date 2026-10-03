import QtQuick
import QtMultimedia
import "../../Utils"

// A video wallpaper: looped, without sound. In a file of its own so that without QtMultimedia
// only videos fail, not the whole wallpaper.
Item {
    id: root

    required property url source
    // The wallpaper window; this video goes once the window's current item is a newer one, shown
    required property var host
    property bool ready: false
    property real reveal: 0
    // Paused keeps the frame on screen and lets the video decoder idle
    readonly property bool playing: host.playing
    // Where on the screen the reveal starts, 0..1
    required property point revealFrom

    anchors.fill: parent

    // Only while revealed: a layer renders every video frame once more
    layer.enabled: reveal < 1
    layer.effect: DiscReveal {
        progress: root.reveal
        center: root.revealFrom
    }

    MediaPlayer {
        id: player

        source: root.source
        videoOutput: output
        loops: MediaPlayer.Infinite
        onErrorOccurred: (error, errorString) => Logger.warn("Wallpaper video not played:", root.source, errorString)
    }

    VideoOutput {
        id: output

        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    // Ready on the first frame, not on load, so the reveal never shows an empty frame
    Connections {
        target: output.videoSink
        enabled: !root.ready
        function onVideoFrameChanged() {
            root.ready = true;
            if (!root.playing)
                player.pause();
        }
    }

    NumberAnimation on reveal {
        running: root.ready
        to: 1
        duration: root.host.revealDuration
        easing.type: Easing.InOutCubic
    }

    Timer {
        running: root.host.current !== root && root.host.current?.ready === true
        interval: root.host.revealDuration
        onTriggered: root.destroy()
    }

    // Played even when it starts hidden, until its first frame: a paused player shows nothing
    onPlayingChanged: {
        if (playing)
            player.play();
        else if (ready)
            player.pause();
    }
    Component.onCompleted: player.play()
}
