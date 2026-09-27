pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

/**
 * ThemeService - Service for managing desktop color themes
 *
 * Colors come from theme-set, which writes ~/.cache/theme/dms-colors.json via
 * the DMS matugen pipeline. Both files are watched, so the shell recolors itself
 * whenever the theme changes - no IPC round trip needed.
 *
 * Exposes the material roles Theme.qml uses, plus the two base16 ansi slots
 * (base08 red, base09 orange) that have no material equivalent.
 */
Singleton {
    id: root

    readonly property string stateDir: `${Quickshell.env("HOME")}/.cache/theme`
    readonly property string themeSetBin: `${Quickshell.env("HOME")}/dotfiles/scripts/theme-set`

    // Active theme, mirrored from state.json
    property string currentTheme: "unknown"
    property string mode: "dark"

    // Material roles
    property string background: "#000000"
    property string surfaceContainer: "#1a1a1a"
    property string surfaceContainerHigh: "#333333"
    property string surfaceText: "#d0d0d0"
    property string surfaceVariantText: "#b3b3b3"
    property string primary: "#5f27cd"
    property string primaryTextColor: "#000000"
    property string secondary: "#ee5a6f"
    property string error: "#ff6b6b"

    // base16 slots with no material role
    property string base08: "#ff6b6b"  // Variables, XML Tags, Markup Link Text
    property string base09: "#ff9f43"  // Integers, Boolean, Constants

    // Raw parse of dms-colors.json, re-applied whenever either file lands
    property var colorData: null

    FileView {
        id: colorsFile
        path: `${root.stateDir}/dms-colors.json`
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        onLoaded: {
            try {
                root.colorData = JSON.parse(text());
                root.applyColors();
            } catch (e) {
                Logger.error("Failed to parse dms-colors.json:", e);
            }
        }

        onLoadFailed: function (error) {
            Logger.warn("No theme colors yet, using defaults - run theme-set:", error);
        }
    }

    FileView {
        id: stateFile
        path: `${root.stateDir}/state.json`
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        onLoaded: {
            try {
                const state = JSON.parse(text());
                root.currentTheme = state.theme || root.currentTheme;
                root.mode = state.mode || "dark";
                // may land before or after the colors file; re-apply either way
                root.applyColors();
            } catch (e) {
                Logger.error("Failed to parse state.json:", e);
            }
        }

        onLoadFailed: function (error) {
            Logger.warn("No theme state yet:", error);
        }
    }

    /**
     * Map the generated palette onto our properties.
     * base16 slots follow the same mapping theme-set exports to its modules:
     * the ansi slots come from dank16.
     */
    function applyColors() {
        if (!root.colorData)
            return;

        const c = root.colorData.colors ? root.colorData.colors[root.mode] : null;
        const k = root.colorData.dank16;
        if (!c || !k) {
            Logger.error("dms-colors.json missing colors or dank16");
            return;
        }

        const ansi = n => k[`color${n}`][root.mode];

        root.background = c.background;
        root.surfaceContainer = c.surface_container;
        root.surfaceContainerHigh = c.surface_container_high;
        root.surfaceText = c.on_surface;
        root.surfaceVariantText = c.on_surface_variant;
        root.primary = c.primary;
        root.primaryTextColor = c.on_primary;
        root.secondary = c.secondary;
        root.error = c.error;

        root.base08 = ansi(1);
        root.base09 = ansi(9);
    }

    Process {
        id: themeSetter
        running: false

        // dms logs its progress to stderr, so this is only worth surfacing
        // when theme-set actually failed
        stderr: StdioCollector {
            id: themeSetterErr
        }

        onExited: (code, status) => {
            if (code !== 0) {
                Logger.error(`theme-set exited with code ${code}:`, themeSetterErr.text.trim());
            }
        }
    }

    Process {
        id: themeLister
        running: false

        stdout: StdioCollector {
            property var callback: null

            onStreamFinished: {
                // "<id><padding><name><padding>[flavors: ...]" - id is the first field
                const names = text.trim().split('\n').filter(l => l.length > 0).map(l => l.trim().split(/\s+/)[0]);
                if (callback) {
                    callback(names);
                }
            }
        }
    }

    /**
     * Switch the whole desktop to a theme. The colors file changes as a result,
     * which is what actually recolors the shell.
     * @param name - Theme id as listed by listThemes()
     * @param light - Optional, use the light variant
     */
    function setTheme(name, light) {
        themeSetter.command = light ? [root.themeSetBin, name, "--light"] : [root.themeSetBin, name];
        themeSetter.running = true;
    }

    /**
     * Re-read the generated palette. Switching themes goes through setTheme();
     * this only picks up a file written by someone else.
     */
    function loadTheme(name) {
        colorsFile.reload();
        stateFile.reload();
    }

    /**
     * List all available themes
     * @param callback - Function to call with array of theme names
     */
    function listThemes(callback) {
        themeLister.stdout.callback = callback;
        themeLister.command = [root.themeSetBin, "--list"];
        themeLister.running = true;
    }
}
