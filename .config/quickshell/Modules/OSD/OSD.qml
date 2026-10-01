import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Utils"
import "."

Scope {
    id: root

    property string currentIndicator: "volume"
    property bool shown: false

    function triggerOsd(indicatorType) {
        root.currentIndicator = indicatorType;
        root.shown = true;
        osdTimeout.restart();
    }

    Timer {
        id: osdTimeout
        interval: 1000
        onTriggered: root.shown = false
    }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            root.triggerOsd("volume");
        }
        function onMutedChanged() {
            root.triggerOsd("volume");
        }
    }

    Connections {
        target: Audio.source?.audio ?? null
        function onVolumeChanged() {
            root.triggerOsd("microphone");
        }
        function onMutedChanged() {
            root.triggerOsd("microphone");
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            if (!Brightness.available)
                return;
            root.triggerOsd("brightness");
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: osdWindow
            required property var modelData
            property bool monitorIsFocused: Compositor.focusedMonitorName === modelData.name

            screen: modelData
            visible: root.shown && monitorIsFocused
            color: "transparent"

            WlrLayershell.namespace: "bidshell:osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            // From the bar or the screen edge; an open sidebar on the same side pushes it further in
            readonly property int sideMargin: Placement.inset(Placement.osdSide, 50) + (Settings.sidebarVisible && Placement.sidebarSide === Placement.osdSide ? Theme.sidebarWidth : 0)

            anchors {
                left: Placement.osdSide === "left"
                right: Placement.osdSide === "right"
                bottom: true
            }

            WlrLayershell.margins {
                left: Placement.osdSide === "left" ? sideMargin : 0
                right: Placement.osdSide === "right" ? sideMargin : 0
                bottom: (modelData.height / 2) - (contentLayout.implicitHeight / 2)
            }

            implicitWidth: contentLayout.implicitWidth
            implicitHeight: contentLayout.implicitHeight

            Item {
                id: contentLayout
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                implicitHeight: indicatorLoader.item?.implicitHeight ?? 100
                implicitWidth: indicatorLoader.item?.implicitWidth ?? 60

                // One Component per indicator so switching type recreates the item instead of animating the bar between unrelated values.
                Loader {
                    id: indicatorLoader
                    active: osdWindow.visible
                    sourceComponent: {
                        switch (root.currentIndicator) {
                        case "volume":
                            return volumeIndicator;
                        case "microphone":
                            return microphoneIndicator;
                        case "brightness":
                            return brightnessIndicator;
                        }
                        return null;
                    }
                }

                Component {
                    id: volumeIndicator
                    OsdValueIndicator {
                        value: Audio.volume
                        icon: Audio.isMuted ? Lucide.volumeX : Lucide.volume2
                    }
                }

                Component {
                    id: microphoneIndicator
                    OsdValueIndicator {
                        value: Audio.micVolume
                        icon: Audio.isMicMuted ? Lucide.micOff : Lucide.mic
                    }
                }

                Component {
                    id: brightnessIndicator
                    OsdValueIndicator {
                        value: Brightness.brightness
                        icon: Lucide.sun
                    }
                }
            }
        }
    }
}
