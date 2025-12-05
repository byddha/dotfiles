import QtQuick
import Quickshell.Services.Mpris
import "../Config"

Item {
    id: root

    property MprisPlayer activePlayer
    property real value: {
        if (!activePlayer || activePlayer.length <= 0) return 0
        const pos = (activePlayer.position || 0) % Math.max(1, activePlayer.length)
        const calculatedRatio = pos / activePlayer.length
        return Math.max(0, Math.min(1, calculatedRatio))
    }
    property bool isSeeking: false

    implicitHeight: 20

    // Poll position updates - MPRIS doesn't emit change signals automatically
    Timer {
        interval: 300
        running: root.visible && activePlayer && activePlayer.positionSupported
        repeat: true
        onTriggered: {
            if (activePlayer?.positionSupported) {
                activePlayer.positionChanged()
            }
        }
    }

    M3WaveProgress {
        anchors.fill: parent
        visible: activePlayer && activePlayer.length > 0
        value: root.value
        isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: activePlayer && activePlayer.canSeek && activePlayer.length > 0

            property real pendingSeekPosition: -1

            Timer {
                id: seekDebounceTimer
                interval: 150
                onTriggered: {
                    if (parent.pendingSeekPosition >= 0 && activePlayer && activePlayer.canSeek && activePlayer.length > 0) {
                        const clamped = Math.min(parent.pendingSeekPosition, activePlayer.length * 0.99)
                        activePlayer.position = clamped
                        parent.pendingSeekPosition = -1
                    }
                }
            }

            onPressed: (mouse) => {
                root.isSeeking = true
                if (activePlayer && activePlayer.length > 0 && activePlayer.canSeek) {
                    const r = Math.max(0, Math.min(1, mouse.x / parent.width))
                    pendingSeekPosition = r * activePlayer.length
                    seekDebounceTimer.restart()
                }
            }

            onReleased: {
                root.isSeeking = false
                seekDebounceTimer.stop()
                if (pendingSeekPosition >= 0 && activePlayer && activePlayer.canSeek && activePlayer.length > 0) {
                    const clamped = Math.min(pendingSeekPosition, activePlayer.length * 0.99)
                    activePlayer.position = clamped
                    pendingSeekPosition = -1
                }
            }

            onPositionChanged: (mouse) => {
                if (pressed && root.isSeeking && activePlayer && activePlayer.length > 0 && activePlayer.canSeek) {
                    const r = Math.max(0, Math.min(1, mouse.x / parent.width))
                    pendingSeekPosition = r * activePlayer.length
                    seekDebounceTimer.restart()
                }
            }

            onClicked: (mouse) => {
                if (activePlayer && activePlayer.length > 0 && activePlayer.canSeek) {
                    const r = Math.max(0, Math.min(1, mouse.x / parent.width))
                    activePlayer.position = r * activePlayer.length
                }
            }
        }
    }
}
