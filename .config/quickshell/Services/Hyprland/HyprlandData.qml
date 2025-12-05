pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../Utils"

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 * Fetches window list and monitor data via hyprctl commands.
 */
Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var monitors: []

    function updateWindowList() {
        getClients.running = true;
    }

    function updateMonitors() {
        getMonitors.running = true;
    }

    function updateAll() {
        updateWindowList();
        updateMonitors();
    }

    /**
     * Find the largest window in a workspace by area
     * @param workspaceId - ID of the workspace to search
     * @returns Window object with the largest size, or null if no windows
     */
    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = root.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    /**
     * Get grouped app data for a workspace
     * @param workspaceId - ID of the workspace to search
     * @returns Array of objects: [{class: "firefox", count: 3}, ...]
     *          Sorted by count (descending) - most instances first
     */
    function getWorkspaceApps(workspaceId) {
        const windowsInWorkspace = root.windowList.filter(w => w.workspace.id == workspaceId);

        if (windowsInWorkspace.length === 0) {
            return [];
        }

        // Group by class and count instances
        const classMap = {};
        windowsInWorkspace.forEach(win => {
            const windowClass = win.class || "unknown";
            if (!classMap[windowClass]) {
                classMap[windowClass] = {
                    class: windowClass,
                    title: win.title || "",
                    xdgTag: win.xdgTag || "",
                    count: 0
                };
            }
            classMap[windowClass].count++;
        });

        // Convert to array and sort by count (most windows first)
        const appList = Object.values(classMap);
        appList.sort((a, b) => b.count - a.count);

        return appList;
    }

    Component.onCompleted: {
        Logger.info("Initializing HyprlandData service");
        updateAll();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            updateAll();
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                try {
                    root.windowList = JSON.parse(clientsCollector.text);
                    let tempWinByAddress = {};
                    for (var i = 0; i < root.windowList.length; ++i) {
                        var win = root.windowList[i];
                        tempWinByAddress[win.address] = win;
                    }
                    root.windowByAddress = tempWinByAddress;
                    root.addresses = root.windowList.map(win => win.address);
                    Logger.debug("Clients updated:", root.windowList.length, "windows");
                } catch (e) {
                    Logger.error("Failed to parse clients data:", e);
                }
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(monitorsCollector.text);
                    Logger.debug("Monitors updated:", root.monitors.length, "displays");
                } catch (e) {
                    Logger.error("Failed to parse monitors data:", e);
                }
            }
        }
    }
}
