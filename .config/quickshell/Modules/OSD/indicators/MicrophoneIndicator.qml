import QtQuick
import "../../../Services"
import "../../OSD"

/**
 * Microphone indicator for OSD
 * Shows current microphone level and mute state
 */
OsdValueIndicator {
    id: root

    value: Audio.micVolume
    icon: Audio.isMicMuted ? Icons.micMuted : Icons.micOn
}
