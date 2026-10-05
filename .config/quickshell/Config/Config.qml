pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import "../Services"
import "../Utils"

Singleton {
    id: config

    readonly property string configDir: (StandardPaths.writableLocation ? StandardPaths.writableLocation(StandardPaths.ConfigLocation) : "~/.config") + "/bidshell"
    readonly property string configFile: configDir + "/config.json"

    property alias options: adapter

    // As DankMaterialShell's SettingsData: read the file before anything uses the options, or every
    // window is built first with the defaults. blockLoading makes text() wait for the file, and the
    // adapter fills from the dataChanged it sends.
    Component.onCompleted: fileView.text()

    readonly property string primaryMonitor: {
        const monitors = adapter.monitors || {};
        for (const model in monitors) {
            if (monitors[model]?.primary)
                return model;
        }
        const models = Object.keys(monitors);
        return models.length > 0 ? models[0] : (Compositor.monitorFor(Quickshell.screens[0])?.key ?? "");
    }

    // Every setting into the file: its own values, and the defaults of the ones it leaves out. Keys
    // the shell no longer knows are dropped, so the old file is kept beside it, a new copy each time.
    function writeAll() {
        backupConfig.running = true;
    }

    Process {
        id: backupConfig
        command: ["bash", "-c", '[ ! -e "$0" ] || cp -n "$0" "$0.$(date +%Y-%m-%dT%H-%M-%S).bak"', config.configFile.replace("file://", "")]
        onExited: code => {
            if (code === 0)
                fileView.writeAdapter();
            else
                Logger.error("Config not written: no backup of", config.configFile);
        }
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
                fileView.writeAdapter();
            } else {
                Logger.error("Failed to create config directory");
            }
        }
    }

    FileView {
        id: fileView
        path: config.configFile
        watchChanges: true
        blockLoading: true

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
            Logger.debugEnabled = adapter.general.debugLogging;
            Logger.traceEnabled = adapter.general.traceLogging;
        }

        JsonAdapter {
            id: adapter

            property JsonObject notifications: JsonObject {
                // "top-left", "top-center", "top-right", "bottom-left", "bottom-center" or "bottom-right"
                property string position: "bottom-right"

                // Rules evaluated when a window gains focus — each matching rule clears notifications whose fields match.
                // Shape: [{ "focus": { <window fields> }, "match": { <notification fields> } }, ...]
                // Each block ANDs its keys. Values: case-insensitive substring, "/regex/flags", or array (OR).
                // Window fields: appId, title, tag, workspaceId, monitorName, floating, covers
                // Notification fields: appName, desktopEntry, summary, body, urgency, hints.<name>, ...
                // Example:
                // [
                //   { "focus": { "appId": "vesktop" },                    "match": { "desktopEntry": "vesktop" } },
                //   { "focus": { "appId": "zen" },                        "match": { "appName": "Zen" } },
                //   { "focus": { "appId": "slack" },                      "match": { "appName": "Slack", "urgency": ["low", "normal"] } },
                //   { "focus": { "appId": "/(vesktop|slack|telegram)/" }, "match": { "hints.category": "im.received" } }
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
                // "top": hangs from the top and grows down; "bottom": stands on the bottom and grows
                // up, with everything in it in the reverse order (the toggles lowest)
                property string anchor: "top"
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
            // Fields: workspaces ([start, end]), hdrCapable (bool), primary (bool),
            // wallpaper (image or video path, "~/" allowed; empty or absent draws none),
            // wallpaperRecolor (bool: recolor it with the theme palette, needs lutgen, and ffmpeg for a video),
            // wallpaperFluid (bool: the cursor stirs it like a fluid over the empty desktop)
            // Exactly one monitor should set primary: true (notifications).
            property var monitors: (
                // Example:
                // "MO34WQC2": { "workspaces": [1, 5], "hdrCapable": true, "primary": true, "wallpaper": "~/Pictures/wall.jpg" },
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

            property JsonObject ocr: JsonObject {
                // "small" or "medium": the PP-OCRv6 models the region selector reads text with
                // (setup installs both); small is about twice as fast, medium reads better
                property string model: "medium"
            }

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
