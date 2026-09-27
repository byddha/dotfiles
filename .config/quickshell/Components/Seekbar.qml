import QtQuick
import Quickshell.Services.Mpris
import "../Config"

// Seek handling follows DankMaterialShell's DankSeekbar: one seek on release, preview while dragging.
Item {
    id: root

    property MprisPlayer activePlayer
    // Pass MprisController.stableTrackLength: player.length is wrong after a seek on Firefox/Zen.
    property real stableLength: 0
    readonly property bool canSeek: (activePlayer?.canSeek ?? false) && stableLength > 0

    readonly property real playerValue: activePlayer && stableLength > 0 ? clampRatio((activePlayer.position || 0) / stableLength) : 0
    // While dragging, and until the player reports the new position, show the target instead.
    property real previewRatio: -1
    property real value: previewRatio >= 0 ? previewRatio : playerValue

    property bool isSeeking: false
    property real committedRatio: -1
    property int settleChecksRemaining: 0

    implicitHeight: 20

    function clampRatio(ratio) {
        return Math.max(0, Math.min(1, ratio));
    }

    function clampPosition(position) {
        return Math.max(0.1, Math.min(position, stableLength * 0.99));
    }

    function clearPreview() {
        settleTimer.stop();
        committedRatio = -1;
        if (!isSeeking)
            previewRatio = -1;
    }

    // MPRIS doesn't emit position changes by itself
    Timer {
        interval: 300
        running: root.visible && !root.isSeeking && (root.activePlayer?.positionSupported ?? false)
        repeat: true
        onTriggered: root.activePlayer.positionChanged()
    }

    // Holds the preview after a seek until the player catches up, so the bar doesn't jump back.
    Timer {
        id: settleTimer
        interval: 80
        repeat: true
        onTriggered: {
            if (root.isSeeking || root.committedRatio < 0 || Math.abs(root.playerValue - root.committedRatio) <= 0.0015 || root.settleChecksRemaining <= 0) {
                root.clearPreview();
                return;
            }
            root.settleChecksRemaining -= 1;
        }
    }

    M3WaveProgress {
        anchors.fill: parent
        visible: root.stableLength > 0
        value: root.value
        isPlaying: root.activePlayer?.playbackState === MprisPlaybackState.Playing

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: root.canSeek

            onPressed: mouse => {
                root.clearPreview();
                root.isSeeking = true;
                root.previewRatio = root.clampRatio(mouse.x / width);
            }

            onPositionChanged: mouse => {
                if (pressed && root.isSeeking)
                    root.previewRatio = root.clampRatio(mouse.x / width);
            }

            onReleased: {
                root.isSeeking = false;
                if (root.previewRatio < 0 || !root.canSeek)
                    return;
                const position = root.clampPosition(root.previewRatio * root.stableLength);
                root.activePlayer.position = position;
                root.previewRatio = position / root.stableLength;
                root.committedRatio = root.previewRatio;
                root.settleChecksRemaining = 15;
                settleTimer.restart();
            }

            onCanceled: {
                root.isSeeking = false;
                root.clearPreview();
            }
        }
    }
}
