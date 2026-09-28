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

    // Binds of the current submap that have a description, in hyprctl's order
    function processFetchedBinds(hyprBinds) {
        keybindList = hyprBinds.filter(bind => (bind.submap || "") === currentSubmap && bind.description?.trim()).map(bind => ({
                    keys: Compositor.backend.keysLabel(bind.modmask, bind.key),
                    description: bind.description
                }));
        Logger.info(`${keybindList.length} keybinds for submap "${currentSubmap}"`);
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
}
