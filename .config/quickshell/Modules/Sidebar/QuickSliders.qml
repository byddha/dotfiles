import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Components"
import "../../Services"
import "../../Utils"

Card {
    id: root

    title: "Quick Controls"
    collapsible: true
    collapsed: false

    Column {
        width: parent.width
        spacing: Theme.spacingLarge

        // Volume Slider
        Loader {
            width: parent.width
            active: Config.options.sidebar.sliders.showVolume
            visible: active

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

                Component.onCompleted: {
                    Logger.info("Volume slider loaded");
                }
            }
        }

        // Brightness Slider
        Loader {
            width: parent.width
            active: Config.options.sidebar.sliders.showBrightness && Brightness.available
            visible: active

            sourceComponent: Slider {
                icon: Icons.brightness
                value: Brightness.brightness

                onMoved: newValue => {
                    Brightness.setBrightness(newValue);
                }

                Component.onCompleted: {
                    Logger.info("Brightness slider loaded");
                }
            }
        }

        // Microphone Slider
        Loader {
            width: parent.width
            active: Config.options.sidebar.sliders.showMicrophone
            visible: active

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

                Component.onCompleted: {
                    Logger.info("Microphone slider loaded");
                }
            }
        }

        // Keyboard Brightness Slider
        Loader {
            id: kbdLoader
            width: parent.width
            active: (Config.options.sidebar.sliders.showKeyboardBrightness ?? true) && KeyboardBrightness.available
            visible: active

            onActiveChanged: {
                Logger.info("Kbd slider active:", active, "config:", Config.options.sidebar.sliders.showKeyboardBrightness, "available:", KeyboardBrightness.available);
            }

            Component.onCompleted: {
                Logger.info("Kbd Loader created, active:", active);
            }

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

                Component.onCompleted: {
                    Logger.info("Keyboard brightness slider loaded");
                }
            }
        }
    }

    Component.onCompleted: {
        Logger.info("Panel loaded");
    }
}
