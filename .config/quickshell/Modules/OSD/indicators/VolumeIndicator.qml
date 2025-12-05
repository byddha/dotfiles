import QtQuick
import "../../../Services"
import "../../OSD"

/**
 * Volume indicator for OSD
 * Shows current volume level and mute state
 */
OsdValueIndicator {
    id: root

    value: Audio.volume
    icon: Audio.isMuted ? Icons.volumeMuted : Icons.volumeHigh
}
