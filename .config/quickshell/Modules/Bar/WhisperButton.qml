import QtQuick
import "../../Config"
import "../../Services"

// Speech to text: "Listening" with the time, then a spinner until the text is ready
BarItem {
    id: root

    visible: Whisper.active
    tooltipTitle: Whisper.transcribing ? "Transcribing" : "Listening"

    Item {
        implicitWidth: 16
        implicitHeight: 16

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
        font.pixelSize: root.vertical ? 11 : 13
        since: Whisper.listeningSince
    }
}
