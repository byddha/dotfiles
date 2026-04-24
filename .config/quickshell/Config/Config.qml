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

    readonly property string primaryMonitor: {
        const monitors = adapter.monitors || {};
        for (const model in monitors) {
            if (monitors[model]?.primary)
                return model;
        }
        const models = Object.keys(monitors);
        return models.length > 0 ? models[0] : (Quickshell.screens[0]?.model ?? "");
    }

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
            Logger.traceEnabled = adapter.general.traceLogging;
            Logger.debug("Full config:", adapter);
        }

        JsonAdapter {
            id: adapter

            property var notifications: JsonObject {
                property bool enabled: true
                // Rules evaluated when a window gains focus — each matching rule clears notifications whose fields match.
                // Shape: [{ "focus": { <window fields> }, "match": { <notification fields> } }, ...]
                // Each block ANDs its keys. Values: case-insensitive substring, "/regex/flags", or array (OR).
                // Window fields: class, initialClass, title, initialTitle, xdgTag, fullscreen, floating, workspace.id, workspace.name, pid, ...
                // Notification fields: appName, desktopEntry, summary, body, urgency, hints.<name>, ...
                // Example:
                // [
                //   { "focus": { "class": "vesktop" },                    "match": { "desktopEntry": "vesktop" } },
                //   { "focus": { "class": "zen" },                        "match": { "appName": "Zen" } },
                //   { "focus": { "class": "slack" },                      "match": { "appName": "Slack", "urgency": ["low", "normal"] } },
                //   { "focus": { "class": "/(vesktop|slack|telegram)/" }, "match": { "hints.category": "im.received" } }
                // ]
                property var autoClearOnFocus: ([])

                // Arrival-time rules. Each rule: { "match": { <notification fields> }, "set": { <overrides> } }
                // Match uses the same field language as autoClearOnFocus (appName, desktopEntry, summary, body,
                // urgency, hints.<name>; substring / "/regex/flags" / array-OR).
                // All matching rules fire; their `set` dicts are merged in order (last wins).
                // Supported `set` keys:
                //   transient: bool  — auto-discard on popup timeout, never kept in history.
                // Reserved for future use (not yet wired): ignore, popup, timeout, urgency.
                // Example:
                // [
                //   { "match": { "appName": "OpenRazer" }, "set": { "transient": true } }
                // ]
                property var rules: ([])
            }

            property var hyprWhichKey: JsonObject {
                property bool enabled: true
                property int fontSize: 24
            }

            property var general: JsonObject {
                property string base16Theme: "tokyo-night-dark"
                property bool debugLogging: false
                property bool traceLogging: false
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
            // Keys are monitor model strings from EDID (e.g., "MO34WQC2", "0x1920")
            // Fields: workspaces ([start, end]), hdrCapable (bool), primary (bool)
            // Exactly one monitor should set primary: true (lockscreen, notifications).
            property var monitors: (
                // Example:
                // "MO34WQC2": { "workspaces": [1, 5], "hdrCapable": true, "primary": true },
                // "0x1920":   { "workspaces": [6, 8], "hdrCapable": false }
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
            }

            // Custom peripheral battery sources
            // devices: [{ name, type, command, interval, replaces? }]
            // type: trackpad, mouse, keyboard, headset, headphones, speakers, gamepad, phone
            // command: outputs JSON {"percentage": 0-100, "charging": true/false}
            // replaces: UPower model name substring to suppress (optional)
            property var peripheralBatteries: ({
                    devices: [],
                    shutdownReminderThreshold: 40
                })

            property var brandLogos: JsonObject {
                property string apiKey: ""      // logo.dev publishable key (for logo images)
                property string secretKey: ""   // logo.dev secret key (for brand search)
            }

            // RSS/Atom feed notifier
            // feeds: [{ name, url, interval?, whitelist?, format? }]
            // interval: seconds, default 900
            // whitelist: string array of case-insensitive substrings matched against item title;
            //            absent/empty passes everything through
            // format: parser key, default "rss"
            property var rssFeedNotifier: JsonObject {
                property bool enabled: true
                property var feeds: ([])
            }

            property var calendar: JsonObject {
                property bool enabled: true

                property var weather: JsonObject {
                    property bool enabled: true
                    property string location: "Bucharest"  // City name for geocoding
                }

                property var holidays: JsonObject {
                    property bool enabled: true
                    property string countryCode: "RO"  // ISO 3166-1 alpha-2
                }
            }
        }
    }
}
