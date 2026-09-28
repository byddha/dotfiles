import QtQuick
import "../../Config"
import "../../Services"

// Speech to text: "Listening" with the time, then a spinner until the text is ready
BarItem {
    id: root

    visible: Whisper.active
    tooltipTitle: Whisper.transcribing ? "Transcribing" : "Listening"
    tooltipKeys: Compositor.keysFor("Transcribe speech")

    Item {
        implicitWidth: BarLayout.iconSize
        implicitHeight: BarLayout.iconSize

        BarSpinner {
            visible: Whisper.transcribing
            color: Theme.accentYellow
        }
        BarIcon {
            visible: !Whisper.transcribing
            text: Lucide.audioLines
            color: Theme.primary
        }
    }
    BarText {
        visible: !root.vertical
        role: Whisper.transcribing ? "secondary" : "primary"
        text: Whisper.transcribing ? "Transcribing…" : "Listening"
    }
    ElapsedText {
        visible: Whisper.listening
        role: root.vertical ? "primary" : "secondary"
        font.pixelSize: root.vertical ? BarLayout.captionSize : BarLayout.textSize
        since: Whisper.listeningSince
    }
}
