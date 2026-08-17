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
 * Exposes two views of the same palette:
 * - material roles (primary, surfaceContainer, outline, ...) - what Theme.qml uses
 * - base16 (base00-base0F) - kept for widgets that still expect it
 */
Singleton {
    id: root

    readonly property string stateDir: `${Quickshell.env("HOME")}/.cache/theme`
    readonly property string themeSetBin: `${Quickshell.env("HOME")}/dotfiles/scripts/theme-set`

    // Active theme, mirrored from state.json
    property string currentTheme: "unknown"
    property string mode: "dark"
    readonly property bool isLight: mode === "light"

    // Material roles
    property string background: "#000000"
    property string surface: "#000000"
    property string surfaceContainer: "#1a1a1a"
    property string surfaceContainerHigh: "#333333"
    property string surfaceText: "#d0d0d0"
    property string surfaceVariantText: "#b3b3b3"
    property string outline: "#4d4d4d"
    property string outlineVariant: "#333333"
    property string primary: "#5f27cd"
    property string primaryTextColor: "#000000"
    property string primaryContainer: "#2a1a5c"
    property string secondary: "#ee5a6f"
    property string secondaryTextColor: "#000000"
    property string tertiary: "#70a1ff"
    property string error: "#ff6b6b"
    property string errorTextColor: "#000000"

    // Base16 color palette properties
    property string base00: "#000000"  // Default Background
    property string base01: "#1a1a1a"  // Lighter Background (status bars, etc)
    property string base02: "#333333"  // Selection Background
    property string base03: "#4d4d4d"  // Comments, Invisibles
    property string base04: "#b3b3b3"  // Dark Foreground (status bars)
    property string base05: "#d0d0d0"  // Default Foreground (text)
    property string base06: "#e8e8e8"  // Light Foreground
    property string base07: "#ffffff"  // Light Background
    property string base08: "#ff6b6b"  // Variables, XML Tags, Markup Link Text
    property string base09: "#ff9f43"  // Integers, Boolean, Constants
    property string base0A: "#ffd93d"  // Classes, Markup Bold, Search Text
    property string base0B: "#95e1d3"  // Strings, Inherited Class, Markup Code
    property string base0C: "#70a1ff"  // Support, Regular Expressions, Escape Chars
    property string base0D: "#5f27cd"  // Functions, Methods, Attribute IDs
    property string base0E: "#ee5a6f"  // Keywords, Storage, Selector, Markup Italic
    property string base0F: "#c56cf0"  // Deprecated, Opening/Closing Embedded Tags

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
     * surfaces from the material roles, the 16 ansi slots from dank16.
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
        root.surface = c.surface;
        root.surfaceContainer = c.surface_container;
        root.surfaceContainerHigh = c.surface_container_high;
        root.surfaceText = c.on_surface;
        root.surfaceVariantText = c.on_surface_variant;
        root.outline = c.outline;
        root.outlineVariant = c.outline_variant;
        root.primary = c.primary;
        root.primaryTextColor = c.on_primary;
        root.primaryContainer = c.primary_container;
        root.secondary = c.secondary;
        root.secondaryTextColor = c.on_secondary;
        root.tertiary = c.tertiary;
        root.error = c.error;
        root.errorTextColor = c.on_error;

        root.base00 = c.background;
        root.base01 = c.surface_container;
        root.base02 = c.surface_container_high;
        root.base03 = c.outline;
        root.base04 = c.on_surface_variant;
        root.base05 = c.on_surface;
        root.base06 = ansi(7);
        root.base07 = ansi(15);
        root.base08 = ansi(1);
        root.base09 = ansi(9);
        root.base0A = ansi(3);
        root.base0B = ansi(2);
        root.base0C = ansi(6);
        root.base0D = ansi(4);
        root.base0E = ansi(5);
        root.base0F = ansi(13);

        Logger.info(`Theme applied: ${root.currentTheme} (${root.mode})`);
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
                Logger.info(`Found ${names.length} themes`);
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
        Logger.info(`Switching theme: ${name}${light ? " (light)" : ""}`);
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
        Logger.info("Listing available themes");
        themeLister.stdout.callback = callback;
        themeLister.command = [root.themeSetBin, "--list"];
        themeLister.running = true;
    }

    Component.onCompleted: {
        Logger.info("ThemeService initialized");
    }
}
