import QtQuick
import "../../Config"
import "../../Services"
import "../../Components"

// Speech to text: "Listening" with the time, then a spinner until the text is ready
BarItem {
    id: root

    visible: Whisper.active
    tooltipTitle: Whisper.transcribing ? "Transcribing" : "Listening"
    tooltipKeys: Compositor.keysFor("Transcribe speech")

    Item {
        implicitWidth: Theme.iconSize
        implicitHeight: Theme.iconSize

        Spinner {
            visible: Whisper.transcribing
            color: Theme.accentYellow
        }
        Icon {
            visible: !Whisper.transcribing
            text: Lucide.audioLines
            color: Theme.primary
        }
    }
    StyledText {
        visible: !root.vertical
        role: Whisper.transcribing ? "secondary" : "primary"
        text: Whisper.transcribing ? "Transcribing…" : "Listening"
    }
    ElapsedText {
        visible: Whisper.listening
        role: root.vertical ? "primary" : "secondary"
        font.pixelSize: root.vertical ? Theme.fontSizeTiny : Theme.fontSizeBase
        since: Whisper.listeningSince
    }
}
