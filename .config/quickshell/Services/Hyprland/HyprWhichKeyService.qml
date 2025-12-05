pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../Utils"
import ".."

/**
 * HyprWhichKeyService - Service for managing keybind display overlay
 *
 * Provides functionality to:
 * - Fetch keybinds from Hyprland via hyprctl
 * - Display keybinds in a single column list
 * - Handle submap events for automatic display
 * - Support manual triggering via IPC
 */
Singleton {
    property bool visible: false
    property var keybindList: []

    property string currentSubmap: ""

    readonly property var modKeyIcons: ({
            "shift": "⇪",
            "ctrl": Icons.keyCtrl,
            "alt": "",
            "super": Icons.keySuper,
            "caps": Icons.keyCaps,
            "mod2": "Num",
            "mod3": "ScrLk",
            "mod5": "Compose"
        })

    readonly property var extraBinds: [
        {
            key: "[q-r]",
            modmask: 64,
            submap: "",
            hasDescription: true,
            description: Icons.keyWorkspace + " Switch workspace [1-5]"
        },
        {
            key: "[q-r]",
            modmask: 65,
            submap: "",
            hasDescription: true,
            description: Icons.keyWorkspace + " Move workspace [1-5]"
        },
        {
            key: "[a-g]",
            modmask: 64,
            submap: "",
            hasDescription: true,
            description: Icons.keyWorkspace + " Switch workspace [6-10]"
        },
        {
            key: "[a-g]",
            modmask: 65,
            submap: "",
            hasDescription: true,
            description: Icons.keyWorkspace + " Move workspace [6-10]"
        }
    ]

    // Process to fetch keybinds from Hyprland
    Process {
        id: bindsFetcher
        command: ["hyprctl", "binds", "-j"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const bindsData = JSON.parse(text);
                    Logger.info(`Fetched ${bindsData.length} keybinds from hyprctl`);
                    processFetchedBinds(bindsData);
                } catch (e) {
                    Logger.warn("Failed to parse binds from hyprctl:", e);
                    processFetchedBinds([]);
                }
            }
        }
    }

    // Monitor Hyprland events for submap changes
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const eventName = event.name;
            if (eventName === "submap") {
                const eventData = event.parse(1);
                const submapName = eventData[0] || "";

                Logger.info(`Submap event: "${submapName}"`);

                if (submapName === "") {
                    // Exited submap
                    visible = false;
                } else {
                    // Entered submap
                    setBinds(submapName);
                    visible = true;
                }
            }
        }
    }

    function processFetchedBinds(hyprBinds) {
        // Convert hyprctl format to our format if needed
        const convertedBinds = hyprBinds.map(bind => ({
                    key: bind.key,
                    modmask: bind.modmask,
                    submap: bind.submap || "",
                    hasDescription: bind.description && bind.description.trim() !== "",
                    description: bind.description,
                    dispatcher: bind.dispatcher,
                    arg: bind.arg
                }));

        // Combine extra binds with real binds, filter by current submap and description
        let binds = [...extraBinds, ...convertedBinds].filter(bind => bind.submap === currentSubmap && bind.hasDescription).sort((a, b) => {
            // Make non-submap dispatchers appear first (AGS logic)
            const aIsSubmap = a.dispatcher === "submap" ? 0.5 : -0.5;
            const bIsSubmap = b.dispatcher === "submap" ? 0.5 : -0.5;
            return aIsSubmap - bIsSubmap;
        });

        Logger.info(`Filtered to ${binds.length} binds for submap "${currentSubmap}"`);

        // Store binds as a flat list
        keybindList = binds;
        Logger.info(`Generated keybind list with ${binds.length} total binds`);
    }

    function toggleManual() {
        if (visible) {
            visible = false;
            return;
        }

        setBinds("");
        visible = true;
    }

    function setBinds(submap) {
        currentSubmap = submap;
        Logger.info(`Fetching keybinds for submap "${submap}"`);
        bindsFetcher.running = true;
    }

    /**
     * Convert modmask bitmask to modifier key strings
     */
    function modmaskToKeys(modmask) {
        const modkeys = ["shift", "caps", "ctrl", "alt", "mod2", "mod3", "super", "mod5"];
        return modkeys.filter((_, i) => (modmask >> i) & 1).map(key => `<${key}>`).reverse().join(" ");
    }

    /**
     * Get formatted key string with modifier icons
     */
    function getRawKey(bind) {
        let mod = modmaskToKeys(bind.modmask);
        for (const [placeholder, icon] of Object.entries(modKeyIcons)) {
            if (icon) {
                const regex = new RegExp(`<${placeholder}>`, 'g');
                mod = mod.replace(regex, icon);
            }
        }
        return `${mod} ${bind.key}`.trim();
    }

    /**
     * Parse description to separate glyph and text parts
     */
    function parseDescription(description) {
        if (!description)
            return {
                glyph: "",
                text: " No description"
            };

        // Use simpler ASCII check instead of Unicode regex
        if (description.length > 0 && !/^[a-zA-Z0-9]/.test(description)) {
            // Handle Unicode characters properly by using codePoint methods
            const firstChar = description.codePointAt(0) ? String.fromCodePoint(description.codePointAt(0)) : description[0];
            const restText = firstChar.length > 1 ? description.substring(2) : description.substring(1);
            return {
                glyph: " " + firstChar,
                text: restText
            };
        }

        return {
            glyph: "",
            text: " " + description
        };
    }
}
