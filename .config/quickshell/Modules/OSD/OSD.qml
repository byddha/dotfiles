import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Config"
import "../../Services"
import "../../Utils"
import "."

/**
 * On-Screen Display (OSD) system
 * Shows overlay indicators for volume, microphone, and brightness changes
 */
Scope {
    id: root

    // Track which indicator to show
    property string currentIndicator: "volume"

    // Available indicators
    property var indicators: [
        { id: "volume", sourceUrl: "indicators/VolumeIndicator.qml" },
        { id: "microphone", sourceUrl: "indicators/MicrophoneIndicator.qml" },
        { id: "brightness", sourceUrl: "indicators/BrightnessIndicator.qml" }
    ]

    // Show OSD and restart timeout
    function triggerOsd(indicatorType) {
        root.currentIndicator = indicatorType;
        Settings.osdVisible = true;
        osdTimeout.restart();
        Logger.info(`Showing ${indicatorType} indicator`);
    }

    // Auto-hide timer
    Timer {
        id: osdTimeout
        interval: Config.options.osd?.timeout ?? 1000
        repeat: false
        running: false
        onTriggered: {
            Settings.osdVisible = false;
            Logger.info("Auto-hiding after timeout");
        }
    }

    // Listen for volume changes
    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (!Config.options.osd?.enabled) return;
            root.triggerOsd("volume");
        }
        function onMutedChanged() {
            if (!Config.options.osd?.enabled) return;
            root.triggerOsd("volume");
        }
    }

    // Listen for microphone changes
    Connections {
        target: Audio.source?.audio ?? null
        function onVolumeChanged() {
            if (!Config.options.osd?.enabled) return;
            root.triggerOsd("microphone");
        }
        function onMutedChanged() {
            if (!Config.options.osd?.enabled) return;
            root.triggerOsd("microphone");
        }
    }

    // Listen for brightness changes
    Connections {
        target: Brightness
        function onBrightnessChanged() {
            if (!Config.options.osd?.enabled) return;
            if (!Brightness.available) return;
            root.triggerOsd("brightness");
        }
    }

    // OSD Window - matching Overview's pattern exactly
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: osdWindow
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(osdWindow.screen)
            property bool monitorIsFocused: Hyprland.focusedMonitor?.id === monitor?.id

            screen: modelData
            visible: Settings.osdVisible && Config.options.osd?.enabled && monitorIsFocused
            color: "transparent"

            WlrLayershell.namespace: "bidshell:osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            // Match Overview's anchor pattern exactly
            anchors {
                right: true
                bottom: true
            }

            // Match Overview's margin pattern exactly
            WlrLayershell.margins {
                right: Settings.sidebarVisible ? (Config.options.sidebar.width + 50) : 50
                bottom: (modelData.height / 2) - (contentLayout.implicitHeight / 2)
            }

            implicitWidth: contentLayout.implicitWidth
            implicitHeight: contentLayout.implicitHeight

            ColumnLayout {
                id: contentLayout
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }

                Item {
                    id: osdContainer
                    implicitHeight: indicatorLoader.item?.implicitHeight ?? 100
                    implicitWidth: indicatorLoader.item?.implicitWidth ?? 60

                    Loader {
                        id: indicatorLoader
                        active: osdWindow.visible
                        source: root.indicators.find(i => i.id === root.currentIndicator)?.sourceUrl ?? ""
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        Logger.info("OSD system initialized");
    }
}
