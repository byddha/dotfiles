import QtQuick
import "../../Services"

LevelButton {
    name: "Microphone"
    glyph: Lucide.mic
    mutedGlyph: Lucide.micOff
    amount: Audio.micVolume
    muted: Audio.isMicMuted
    deviceLabel: "Input"
    device: Audio.source ? Audio.friendlyDeviceName(Audio.source) : ""

    onToggleMute: Audio.toggleMicMute()
    onRaise: Audio.increaseMicVolume()
    onLower: Audio.decreaseMicVolume()
}
