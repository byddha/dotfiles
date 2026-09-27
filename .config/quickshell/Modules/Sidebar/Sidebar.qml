import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: sidebarWindow
            required property ShellScreen modelData

            screen: modelData
            visible: Settings.sidebarVisible && modelData.name === Compositor.focusedMonitorName

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "bidshell:sidebar"
            WlrLayershell.keyboardFocus: sidebarWindow.visible ? (Compositor.useHyprlandFocusGrab ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None
            WlrLayershell.margins {
                top: 50
                right: 10
                bottom: 10
            }

            exclusiveZone: 0  // Float over windows

            color: "transparent"

            // Click-outside-to-close using HyprlandFocusGrab on Hyprland
            // NOTE: active must NOT be bound to visibility - must be manually controlled
            FocusGrab {
                id: focusGrab
                windows: [sidebarWindow]
                active: false  // Manually activated after window is visible

                onCleared: {
                    Settings.sidebarVisible = false;
                    focusGrab.active = false;
                }
            }

            // As DankMaterialShell's popouts (DankPopoutHost _contentWarm / _surfaceFrameReady): the content
            // stays loaded after the first open so it is never rebuilt (and never visibly re-lays out) while
            // sliding in, and the slide starts only after the window has drawn its first frame.
            property bool contentWarm: false
            property bool presented: false

            Connections {
                target: contentWrapper.Window.window
                enabled: sidebarWindow.visible && !sidebarWindow.presented

                function onFrameSwapped() {
                    sidebarWindow.presented = true;
                }
            }

            // Activate focus grab when sidebar becomes visible
            onVisibleChanged: {
                presented = false;
                if (visible) {
                    contentWarm = true;
                    Hdr.refresh();
                    // Delay slightly to ensure window is ready
                    Qt.callLater(() => {
                        focusGrab.active = Compositor.useHyprlandFocusGrab;
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
                        event.accepted = true;
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: sidebarWindow.visible
                onClicked: Settings.sidebarVisible = false
            }

            // Content wrapper for animations
            Item {
                id: contentWrapper
                width: Theme.sidebarWidth
                height: parent.height
                anchors.right: parent.right
                anchors.top: parent.top

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onPressed: mouse => {
                        mouse.accepted = true;
                    }
                    z: -1
                }

                // Slide in animation
                transform: Translate {
                    x: sidebarWindow.presented ? 0 : contentWrapper.width + 10

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.animation.elementMoveEnter.duration
                            easing.type: Theme.animation.elementMoveEnter.type
                            easing.bezierCurve: Theme.animation.elementMoveEnter.bezierCurve
                        }
                    }
                }

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    active: sidebarWindow.contentWarm

                    sourceComponent: SidebarContent {}

                    opacity: sidebarWindow.presented ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animation.elementMoveFast.duration
                            easing.type: Theme.animation.elementMoveFast.type
                            easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                        }
                    }
                }
            }
        }
    }
}
