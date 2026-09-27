import QtQuick
import "../../Config"
import "../../Components"
import "../../Services"

Card {
    id: root

    title: "Quick Controls"
    collapsible: true

    Column {
        width: parent.width
        spacing: Theme.spacingLarge

        // Volume Slider
        Loader {
            width: parent.width

            sourceComponent: Slider {
                icon: Audio.isMuted ? Icons.volumeMuted : (Audio.volume > 0.5 ? Icons.volumeHigh : Icons.volumeLow)
                value: Audio.volume
                showMuteIcon: true
                isMuted: Audio.isMuted

                onMoved: newValue => {
                    Audio.setVolume(newValue);
                }

                onIconClicked: {
                    Audio.toggleMute();
                }

                onRightClicked: {
                    Audio.toggleMute();
                }
            }
        }

        // Brightness Slider
        Loader {
            width: parent.width
            active: Brightness.available
            visible: active

            sourceComponent: Slider {
                icon: Icons.brightness
                value: Brightness.brightness

                onMoved: newValue => {
                    Brightness.setBrightness(newValue);
                }
            }
        }

        // Microphone Slider
        Loader {
            width: parent.width

            sourceComponent: Slider {
                icon: Audio.isMicMuted ? Icons.micMuted : Icons.micOn
                iconSize: Audio.isMicMuted ? Theme.iconSize : Theme.iconSize - 4
                value: Audio.micVolume
                showMuteIcon: true
                isMuted: Audio.isMicMuted

                onMoved: newValue => {
                    Audio.setMicVolume(newValue);
                }

                onIconClicked: {
                    Audio.toggleMicMute();
                }

                onRightClicked: {
                    Audio.toggleMicMute();
                }
            }
        }

        // Keyboard Brightness Slider
        Loader {
            width: parent.width
            active: KeyboardBrightness.available
            visible: active

            sourceComponent: Slider {
                icon: Icons.keyboard
                value: KeyboardBrightness.brightness
                stepSize: KeyboardBrightness.stepSize
                snapMode: true
                showMuteIcon: true
                isMuted: KeyboardBrightness.brightness === 0

                onMoved: newValue => {
                    KeyboardBrightness.setBrightness(newValue);
                }

                onIconClicked: {
                    KeyboardBrightness.toggle();
                }

                onRightClicked: {
                    KeyboardBrightness.cycle();
                }
            }
        }
    }
}
