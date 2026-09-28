pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import "../Utils"

Singleton {
    id: config

    function init() {
        loadConfig();
    }

    readonly property string configDir: (StandardPaths.writableLocation ? StandardPaths.writableLocation(StandardPaths.ConfigLocation) : "~/.config") + "/bidshell"
    readonly property string configFile: configDir + "/config.json"

    property bool configLoaded: false
    property alias options: adapter

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
            config.configLoaded = true;
            Logger.debugEnabled = adapter.general.debugLogging;
            Logger.traceEnabled = adapter.general.traceLogging;
            Logger.debug("Full config:", adapter);
        }

        JsonAdapter {
            id: adapter

            property JsonObject notifications: JsonObject {
                // "top-left", "top-center", "top-right", "bottom-left", "bottom-center" or "bottom-right"
                property string position: "bottom-right"

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

            property JsonObject general: JsonObject {
                property bool debugLogging: false
                property bool traceLogging: false
            }

            // App icons the shell shows instead of the icon theme's, by desktop entry id (the .desktop file
            // name): an absolute path or another themed icon name. Tray icons come from the apps themselves.
            // Example: { "zen": "/usr/share/icons/hicolor/128x128/apps/zen-browser.png" }
            property var iconOverrides: ({})

            property JsonObject sidebar: JsonObject {
                // "left" or "right": the screen side it opens on
                property string side: "right"
            }

            property JsonObject osd: JsonObject {
                // "left" or "right", vertically centered
                property string position: "right"
            }

            property JsonObject bar: JsonObject {
                // "top", "bottom", "left" or "right"
                property string position: "top"
                // Away from the screen edges, with rounded corners and a shadow
                property bool floating: false
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

            // Custom peripheral battery sources
            // devices: [{ name, type, command, interval, replaces? }]
            // type: trackpad, mouse, keyboard, headset, headphones, speakers, gamepad, phone
            // command: outputs JSON {"percentage": 0-100, "charging": true/false}
            // replaces: UPower model name substring to suppress (optional)
            property var peripheralBatteries: ({
                    devices: []
                })

            property JsonObject brandLogos: JsonObject {
                property string apiKey: ""      // logo.dev publishable key (for logo images)
                property string secretKey: ""   // logo.dev secret key (for brand search)
            }

            // RSS/Atom feed notifier
            // feeds: [{ name, url, interval?, whitelist?, format? }]
            // interval: seconds, default 900
            // whitelist: string array of case-insensitive substrings matched against item title;
            //            absent/empty passes everything through
            // format: parser key, default "rss"
            property JsonObject rssFeedNotifier: JsonObject {
                property var feeds: ([])
            }
        }
    }
}
