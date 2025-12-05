import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Config"
import "../../Utils"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: sidebarWindow
            required property ShellScreen modelData

            screen: modelData
            visible: Settings.sidebarVisible && Config.options.sidebar.enabled && modelData.name === Hyprland.focusedMonitor?.name

            anchors {
                right: true
                top: true
                bottom: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "bidshell:sidebar"
            WlrLayershell.margins {
                top: Config.options.sidebar.marginTop
                right: Config.options.sidebar.marginRight
                bottom: Config.options.sidebar.marginBottom
            }

            exclusiveZone: 0  // Float over windows

            color: "transparent"
            implicitWidth: Config.options.sidebar.width

            // Click-outside-to-close using HyprlandFocusGrab
            // NOTE: active must NOT be bound to visibility - must be manually controlled
            HyprlandFocusGrab {
                id: focusGrab
                windows: [sidebarWindow]
                active: false  // Manually activated after window is visible

                onCleared: {
                    Logger.info("Focus cleared (clicked outside or Escape)");
                    Settings.sidebarVisible = false;
                    focusGrab.active = false;
                }
            }

            // Activate focus grab when sidebar becomes visible
            onVisibleChanged: {
                if (visible) {
                    // Delay slightly to ensure window is ready
                    Qt.callLater(() => {
                        focusGrab.active = true;
                        Logger.info("Focus grab activated");
                    });
                } else {
                    focusGrab.active = false;
                }
            }

            // Keyboard focus for Escape key handling
            Item {
                id: keyHandler
                focus: sidebarWindow.visible
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        Settings.sidebarVisible = false;
                        Logger.info("Closed via Escape key");
                        event.accepted = true;
                    }
                }
            }

            // Content wrapper for animations
            Item {
                id: contentWrapper
                anchors.fill: parent

                // Slide in animation
                transform: Translate {
                    x: Settings.sidebarVisible ? 0 : sidebarWindow.width

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.animation.elementMoveEnter.duration
                            easing.type: Theme.animation.elementMoveEnter.type
                            easing.bezierCurve: Theme.animation.elementMoveEnter.bezierCurve
                        }
                    }
                }

                // Lazy load content
                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    active: Settings.sidebarVisible

                    sourceComponent: SidebarContent {}

                    // Fade in animation
                    opacity: Settings.sidebarVisible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animation.elementMoveFast.duration
                            easing.type: Theme.animation.elementMoveFast.type
                            easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                        }
                    }
                }
            }

            Component.onCompleted: {
                Logger.info(`Initialized on screen ${modelData.name}`);
            }
        }
    }
}
