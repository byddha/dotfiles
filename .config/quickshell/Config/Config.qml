pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import "../Utils"
import "../Services"

Singleton {
    id: config

    function init() {
        loadConfig();
    }

    readonly property string configDir: (StandardPaths.writableLocation ? StandardPaths.writableLocation(StandardPaths.ConfigLocation) : "~/.config") + "/bidshell"
    readonly property string configFile: configDir + "/config.json"

    property bool configLoaded: false
    property alias options: adapter
    property string lastLoadedTheme: ""

    function loadConfig() {
        fileView.reload();
    }

    function saveConfig() {
        fileView.writeAdapter();
    }

    Timer {
        id: reloadTimer
        interval: 100
        onTriggered: {
            Logger.debug("Reload timer triggered");
            fileView.reload();
        }
    }

    Process {
        id: createDefaultConfig
        command: ["mkdir", "-p", config.configDir]
        onExited: (code, status) => {
            if (code === 0) {
                Logger.info("Config directory created, saving defaults...");
                config.configLoaded = true;
                fileView.writeAdapter();
                ThemeService.loadTheme(adapter.general.base16Theme);
                config.lastLoadedTheme = adapter.general.base16Theme;
            } else {
                Logger.error("Failed to create config directory");
                config.configLoaded = true;
            }
        }
    }

    FileView {
        id: fileView
        path: config.configFile
        watchChanges: true

        onFileChanged: {
            Logger.info("Config file changed");
            reloadTimer.restart();
        }

        onLoadFailed: function (error) {
            Logger.warn("Failed to load config:", error);
            Logger.info("Creating config with defaults...");
            createDefaultConfig.running = true;
        }

        onLoaded: {
            Logger.info("Config loaded from:", config.configFile);
            const newTheme = adapter.general.base16Theme;

            // Load theme on first load or if theme changed
            if (!config.configLoaded || config.lastLoadedTheme !== newTheme) {
                Logger.info(`Theme ${config.configLoaded ? "changed to" : "loaded"}:`, newTheme);
                ThemeService.loadTheme(newTheme);
                config.lastLoadedTheme = newTheme;
            } else {
                Logger.debug("Theme unchanged, skipping reload");
            }

            config.configLoaded = true;
            Logger.debugEnabled = adapter.general.debugLogging;
            Logger.debug("Full config:", adapter);
        }

        JsonAdapter {
            id: adapter

            property var notifications: JsonObject {
                property bool enabled: true
                property int timeout: 5000
                property int maxVisible: 3
            }

            property var hyprWhichKey: JsonObject {
                property bool enabled: true
                property int fontSize: 24
            }

            property var general: JsonObject {
                property string base16Theme: "tokyo-night-dark"
                property bool debugLogging: false
            }

            property var bar: JsonObject {
                property bool enabled: true
                property string position: "top"

                property var tray: JsonObject {
                    property bool enabled: true
                    property bool showTooltips: true
                }
            }

            property var overview: JsonObject {
                property bool enabled: true
                property real scale: 0.08
            }

            // Centralized monitor configuration
            // Keys are monitor names (e.g., "DP-3", "HDMI-A-1")
            // Each monitor can have: workspaces (array [start, end]), forceRotate (bool), hdrCapable (bool)
            property var monitors: (
                // Example:
                // "DP-3": { "workspaces": [1, 5], "forceRotate": false, "hdrCapable": true },
                // "HDMI-A-1": { "workspaces": [6, 8], "forceRotate": true, "hdrCapable": false }
                {})

            property var sidebar: JsonObject {
                property bool enabled: true
                property int width: 400
                property int marginTop: 50
                property int marginRight: 10
                property int marginBottom: 10

                property var sliders: JsonObject {
                    property bool showVolume: true
                    property bool showBrightness: true
                    property bool showMicrophone: true
                    property bool showKeyboardBrightness: true
                }
            }

            property var osd: JsonObject {
                property bool enabled: true
                property int timeout: 1000
                property string position: "right"  // "left" or "right"
            }

            property var calendar: JsonObject {
                property bool enabled: true

                property var weather: JsonObject {
                    property bool enabled: true
                    property string location: "London"  // City name for geocoding
                }
            }
        }
    }
}
