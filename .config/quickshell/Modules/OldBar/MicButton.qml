import QtQuick
import "../../Services"

AudioPill {
    icon: Audio.isMicMuted ? Icons.micMuted : Icons.micOn
    iconPixelSize: Audio.isMicMuted ? BarStyle.iconSize : BarStyle.iconSize - 4
    muted: Audio.isMicMuted
    level: Audio.micVolume
    onToggleMute: Audio.toggleMicMute()
    onIncrease: Audio.increaseMicVolume()
    onDecrease: Audio.decreaseMicVolume()
}
