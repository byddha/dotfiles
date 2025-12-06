import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Config"
import "../../Services"
import "../../Utils"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: launcherWindow
            required property ShellScreen modelData

            screen: modelData
            visible: Settings.gameLauncherVisible && modelData.name === Hyprland.focusedMonitor?.name

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "bidshell:gamelauncher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            exclusiveZone: 0
            color: Theme.colLayer0

            // Click-outside-to-close using HyprlandFocusGrab
            HyprlandFocusGrab {
                id: focusGrab
                windows: [launcherWindow]
                active: false

                onCleared: {
                    Logger.info("GameLauncher: Focus cleared");
                    Settings.gameLauncherVisible = false;
                    focusGrab.active = false;
                }
            }

            onVisibleChanged: {
                if (visible) {
                    Qt.callLater(() => {
                        focusGrab.active = true;
                        Logger.info("GameLauncher: Focus grab activated");
                    });
                    GameService.refresh();
                } else {
                    focusGrab.active = false;
                    GameService.searchQuery = "";
                }
            }

            // Content with fade animation
            Loader {
                id: contentLoader
                anchors.fill: parent
                active: Settings.gameLauncherVisible

                sourceComponent: GameLauncherContent {}

                opacity: Settings.gameLauncherVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animation.elementMoveFast.duration
                        easing.type: Theme.animation.elementMoveFast.type
                        easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                    }
                }
            }

            Component.onCompleted: {
                Logger.info(`GameLauncher: Initialized on screen ${modelData.name}`);
            }
        }
    }
}
