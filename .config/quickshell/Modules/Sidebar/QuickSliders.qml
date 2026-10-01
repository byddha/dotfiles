import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Components"
import "../../Services"

Card {
    id: root

    padding: 8
    spacing: 4

    function volumeIcon(volume, muted) {
        if (muted || volume <= 0)
            return Lucide.volumeX;
        if (volume < 0.34)
            return Lucide.volume;
        if (volume < 0.67)
            return Lucide.volume1;
        return Lucide.volume2;
    }

    Slider {
        Layout.fillWidth: true
        icon: root.volumeIcon(Audio.volume, Audio.isMuted)
        value: Audio.volume
        to: 1.5
        showMuteIcon: true
        isMuted: Audio.isMuted
        onMoved: newValue => Audio.setVolume(newValue, 1.5)
        onIconClicked: Audio.toggleMute()
        onRightClicked: Audio.toggleMute()
    }

    Slider {
        Layout.fillWidth: true
        icon: Audio.isMicMuted ? Lucide.micOff : Lucide.mic
        value: Audio.micVolume
        to: 1.5
        showMuteIcon: true
        isMuted: Audio.isMicMuted
        onMoved: newValue => Audio.setMicVolume(newValue, 1.5)
        onIconClicked: Audio.toggleMicMute()
        onRightClicked: Audio.toggleMicMute()
    }

    Loader {
        Layout.fillWidth: true
        active: Brightness.available
        visible: active

        sourceComponent: Slider {
            icon: Lucide.sun
            value: Brightness.brightness
            onMoved: newValue => Brightness.setBrightness(newValue)
        }
    }

    Loader {
        Layout.fillWidth: true
        active: KeyboardBrightness.available
        visible: active

        sourceComponent: Slider {
            icon: Lucide.keyboard
            value: KeyboardBrightness.brightness
            stepSize: KeyboardBrightness.stepSize
            snapMode: true
            labelText: `${Math.round(KeyboardBrightness.brightness / KeyboardBrightness.stepSize)}/${Math.round(1 / KeyboardBrightness.stepSize)}`
            onMoved: newValue => KeyboardBrightness.setBrightness(newValue)
            onIconClicked: KeyboardBrightness.toggle()
            onRightClicked: KeyboardBrightness.cycle()
        }
    }
}
