import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Config"
import "../../Utils"
import "../../Components"

/**
 * CalendarPanel - Calendar popup panel module
 *
 * Shows a calendar with date banner, month grid, and optional weather.
 * Opens when clicking the clock in the bar.
 * Uses PanelWindow with HyprlandFocusGrab for click-outside-to-close.
 */
Scope {
    id: root

    // Track the active window for focus grab
    property var activeWindow: null

    // Focus grab at Scope level (like Tray pattern)
    HyprlandFocusGrab {
        id: focusGrab
        windows: root.activeWindow ? [root.activeWindow] : []
        active: Settings.calendarPanelVisible && root.activeWindow !== null

        onCleared: {
            if (Settings.calendarPanelVisible) {
                Settings.calendarPanelVisible = false;
                Logger.info("Closed via focus grab (click outside or Escape)");
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: calendarWindow
            required property ShellScreen modelData

            screen: modelData
            visible: Settings.calendarPanelVisible && (Config.options.calendar?.enabled ?? true) && modelData.name === Hyprland.focusedMonitor?.name

            // Position: top-right, below bar
            anchors {
                top: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "bidshell:calendarpanel"
            WlrLayershell.margins {
                top: (Config.options.bar?.height ?? 32) + Theme.spacingBase
                // Align with Clock: PowerButton width + 2x spacing (between items + bar margin)
                right: (Config.options.bar?.height ?? 32) + Theme.spacingBase * 3
            }

            exclusiveZone: 0  // Float over windows

            color: "transparent"
            // Account for wrapper margins (Theme.spacingBase on each side)
            implicitWidth: (contentLoader.item?.implicitWidth ?? 380) + Theme.spacingBase * 2
            implicitHeight: (contentLoader.item?.implicitHeight ?? 400) + Theme.spacingBase * 2

            // Register this window for focus grab when it becomes active
            onVisibleChanged: {
                if (visible && modelData.name === Hyprland.focusedMonitor?.name) {
                    root.activeWindow = calendarWindow;
                    Logger.info("Registered window for focus grab");
                } else if (!visible && root.activeWindow === calendarWindow) {
                    root.activeWindow = null;
                }
            }

            // Background with shadow
            Item {
                anchors.fill: parent

                Rectangle {
                    id: panelBg
                    anchors.fill: parent
                    color: Theme.colLayer0
                    radius: Theme.radiusBase
                    border.color: Theme.colLayer0Border
                    border.width: 1

                    // Content wrapper for animations
                    Item {
                        id: contentWrapper
                        anchors.fill: parent
                        anchors.margins: Theme.spacingBase

                        // Fade in animation
                        opacity: Settings.calendarPanelVisible ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animation.elementMoveFast.duration
                                easing.type: Theme.animation.elementMoveFast.type
                                easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                            }
                        }

                        // Lazy load content
                        Loader {
                            id: contentLoader
                            anchors.fill: parent
                            active: Settings.calendarPanelVisible

                            sourceComponent: CalendarPanelContent {}
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
