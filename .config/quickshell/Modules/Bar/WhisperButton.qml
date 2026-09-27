import QtQuick
import "../../Config"
import "../../Services"

ActivityPill {
    visible: Whisper.recording
    icon: Icons.micOn
    iconColor: Theme.accentOrange
    label: "Transcribing"
}
