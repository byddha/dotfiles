import QtQuick
import "../../Services"

LevelButton {
    name: "Volume"
    glyph: Audio.volume > 0.66 ? Lucide.volume2 : Audio.volume > 0.33 ? Lucide.volume1 : Lucide.volume
    mutedGlyph: Lucide.volumeX
    amount: Audio.volume
    muted: Audio.isMuted || Audio.volume === 0
    deviceLabel: "Output"
    device: Audio.sink ? Audio.friendlyDeviceName(Audio.sink) : ""

    onToggleMute: Audio.toggleMute()
    onRaise: Audio.increaseVolume()
    onLower: Audio.decreaseVolume()
}
