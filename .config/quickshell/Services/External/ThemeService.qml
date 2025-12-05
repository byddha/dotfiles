pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

/**
 * ThemeService - Service for managing base16 color themes
 *
 * Provides functionality to:
 * - Load base16 themes from YAML files
 * - Convert YAML to JSON using yq
 * - Expose base16 color palette (base00-base0F)
 * - Support dynamic theme switching
 * - List available themes
 */
Singleton {
    id: root

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

    // Theme metadata
    property string themeName: "default"
    property string themeAuthor: ""
    property string themeVariant: "dark"

    // State
    property bool isLoading: false
    property string lastError: ""

    // Base16 directory path
    readonly property string base16Dir: "/home/bida/.config/base16"

    // Process to convert YAML to JSON using yq
    Process {
        id: yamlConverter
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const themeData = JSON.parse(text);
                    Logger.info(`Loaded theme: ${themeData.name || "unknown"}`);
                    applyTheme(themeData);
                    root.isLoading = false;
                    root.lastError = "";
                } catch (e) {
                    Logger.error("Failed to parse theme JSON:", e);
                    root.lastError = "Failed to parse theme data: " + e;
                    root.isLoading = false;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    Logger.warn("yq stderr:", text);
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                Logger.error(`yq exited with code ${code}`);
                root.lastError = "Failed to load theme file";
                root.isLoading = false;
            }
        }
    }

    // Process to list available themes
    Process {
        id: themeLister
        running: false

        stdout: StdioCollector {
            property var callback: null

            onStreamFinished: {
                const files = text.trim().split('\n').filter(f => f.length > 0);
                const themeNames = files.map(f => f.replace(/\.yaml$/, ''));
                Logger.info(`Found ${themeNames.length} themes`);
                if (callback) {
                    callback(themeNames);
                }
            }
        }
    }

    /**
     * Load a base16 theme by name
     * @param name - Theme name (without .yaml extension)
     */
    function loadTheme(name) {
        const themePath = `${base16Dir}/${name}.yaml`;
        Logger.info(`Loading theme: ${themePath}`);

        root.isLoading = true;
        root.themeName = name;

        yamlConverter.command = ["yq", ".", themePath];
        yamlConverter.running = true;
    }

    /**
     * Apply parsed theme data to properties
     */
    function applyTheme(themeData) {
        if (!themeData.palette) {
            Logger.error("Theme data missing 'palette' key");
            return;
        }

        const p = themeData.palette;

        // Apply base16 colors
        root.base00 = p.base00 || root.base00;
        root.base01 = p.base01 || root.base01;
        root.base02 = p.base02 || root.base02;
        root.base03 = p.base03 || root.base03;
        root.base04 = p.base04 || root.base04;
        root.base05 = p.base05 || root.base05;
        root.base06 = p.base06 || root.base06;
        root.base07 = p.base07 || root.base07;
        root.base08 = p.base08 || root.base08;
        root.base09 = p.base09 || root.base09;
        root.base0A = p.base0A || root.base0A;
        root.base0B = p.base0B || root.base0B;
        root.base0C = p.base0C || root.base0C;
        root.base0D = p.base0D || root.base0D;
        root.base0E = p.base0E || root.base0E;
        root.base0F = p.base0F || root.base0F;

        // Apply metadata
        root.themeAuthor = themeData.author || "";
        root.themeVariant = themeData.variant || "dark";

        Logger.info(`Theme applied: ${themeData.name} by ${root.themeAuthor}`);
    }

    /**
     * List all available themes
     * @param callback - Function to call with array of theme names
     */
    function listThemes(callback) {
        Logger.info("Listing available themes");
        themeLister.stdout.callback = callback;
        themeLister.command = ["ls", base16Dir];
        themeLister.running = true;
    }

    /**
     * Initialize with default theme
     */
    Component.onCompleted: {
        Logger.info("ThemeService initialized");
    }
}
