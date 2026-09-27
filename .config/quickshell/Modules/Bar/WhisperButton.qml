import QtQuick
import "../../Config"
import "../../Services"

ActivityPill {
    visible: Whisper.active
    busy: Whisper.transcribing
    icon: Icons.micOn
    iconColor: Theme.accentOrange
    label: Whisper.transcribing ? "Transcribing…" : "Listening"
}
