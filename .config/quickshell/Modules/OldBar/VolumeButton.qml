import QtQuick
import "../../Services"

AudioPill {
    icon: {
        if (Audio.isMuted || Audio.volume === 0)
            return Icons.volumeMuted;
        else if (Audio.volume > 0.66)
            return Icons.volumeHigh;
        else if (Audio.volume > 0.33)
            return Icons.volumeMedium;
        else
            return Icons.volumeLow;
    }
    muted: Audio.isMuted
    level: Audio.volume
    onToggleMute: Audio.toggleMute()
    onIncrease: Audio.increaseVolume()
    onDecrease: Audio.decreaseVolume()
}
