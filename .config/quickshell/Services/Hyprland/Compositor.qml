pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../Utils"

Singleton {
    id: compositor

    property string type: "hyprland"
    property bool isHyprland: true

    property var workspaces: []
    property int activeWorkspace: 1
    property string activeWindow: ""
    property string activeWindowClass: ""
    property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""
    property int focusedMonitorId: Hyprland.focusedMonitor?.id ?? -1

    // Data from hyprctl (absorbed from HyprlandData)
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var monitors: []

    signal workspaceFocusChanged()
    signal windowDataUpdated()
    signal monitorDataUpdated()

    Component.onCompleted: {
        detectCompositor();
    }

    function detectCompositor() {
        try {
            if (Hyprland.eventSocketPath) {
                initHyprland();
                Logger.info("Running on Hyprland");
                return;
            }
        } catch (e) {}

        Logger.error("This shell only supports Hyprland. Exiting...");
        Qt.callLater(Qt.quit);
    }

    function initHyprland() {
        updateWorkspaces();
        updateAllData();
    }

    function updateWorkspaces() {
        workspaces = Hyprland.workspaces.values;
        activeWorkspace = Hyprland.focusedWorkspace?.id ?? 1;
        activeWindow = ToplevelManager.activeToplevel?.title ?? "";
        activeWindowClass = ToplevelManager.activeToplevel?.appId ?? "";
    }

    // --- hyprctl data fetching ---

    function updateWindowList() {
        getClients.running = true;
    }

    function updateMonitorData() {
        getMonitors.running = true;
    }

    function updateAllData() {
        updateWindowList();
        updateMonitorData();
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                try {
                    compositor.windowList = JSON.parse(clientsCollector.text);
                    let tempWinByAddress = {};
                    for (var i = 0; i < compositor.windowList.length; ++i) {
                        var win = compositor.windowList[i];
                        tempWinByAddress[win.address] = win;
                    }
                    compositor.windowByAddress = tempWinByAddress;
                    compositor.addresses = compositor.windowList.map(win => win.address);
                    compositor.windowDataUpdated();
                    Logger.debug("Clients updated:", compositor.windowList.length, "windows");
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
                    compositor.monitors = JSON.parse(monitorsCollector.text);
                    compositor.monitorDataUpdated();
                    Logger.debug("Monitors updated:", compositor.monitors.length, "displays");
                } catch (e) {
                    Logger.error("Failed to parse monitors data:", e);
                }
            }
        }
    }

    // --- Data query functions ---

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = compositor.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    function getWorkspaceApps(workspaceId) {
        const windowsInWorkspace = compositor.windowList.filter(w => w.workspace.id == workspaceId);

        if (windowsInWorkspace.length === 0) {
            return [];
        }

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

        const appList = Object.values(classMap);
        appList.sort((a, b) => b.count - a.count);

        return appList;
    }

    function monitorForScreen(screen) {
        const name = screen?.name ?? "";
        const mon = compositor.monitors.find(m => m.name === name);
        if (!mon) return null;
        return {
            name: mon.name,
            id: mon.id,
            x: mon.x,
            y: mon.y,
            width: mon.width,
            height: mon.height,
            scale: mon.scale,
            activeWorkspaceId: mon.activeWorkspace?.id ?? 1,
            transform: mon.transform ?? 0,
            reserved: mon.reserved ?? [0, 0, 0, 0]
        };
    }

    function activeWorkspaceIdForScreen(screen) {
        const mon = monitorForScreen(screen);
        return mon?.activeWorkspaceId ?? 1;
    }

    function windowForToplevel(toplevel) {
        const address = `0x${toplevel.HyprlandToplevel.address}`;
        return compositor.windowByAddress[address] ?? null;
    }

    function getCursorPosition(callback) {
        const proc = cursorPosComponent.createObject(compositor, { callback: callback });
        proc.running = true;
    }

    Component {
        id: cursorPosComponent
        Process {
            property var callback
            command: ["hyprctl", "cursorpos"]
            stdout: SplitParser {
                onRead: data => {
                    const parts = data.trim().split(", ");
                    if (parts.length === 2) {
                        callback(parseInt(parts[0]), parseInt(parts[1]));
                    }
                }
            }
            onExited: destroy()
        }
    }

    function setMonitorColorManagement(name, preset) {
        const proc = cmComponent.createObject(compositor, {
            command: ["hyprctl", "keyword", `monitorv2[${name}]:cm`, preset]
        });
        proc.running = true;
    }

    Component {
        id: cmComponent
        Process {
            onExited: destroy()
        }
    }

    // --- Connections ---

    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            activeWorkspace = Hyprland.focusedWorkspace?.id ?? 1;
            workspaceFocusChanged();
            Logger.debug("Workspace →", activeWorkspace);
        }

        function onFocusedMonitorChanged() {
            focusedMonitorName = Hyprland.focusedMonitor?.name ?? "";
            focusedMonitorId = Hyprland.focusedMonitor?.id ?? -1;
            workspaceFocusChanged();
        }

        function onRawEvent(event) {
            updateAllData();
        }
    }

    Connections {
        target: ToplevelManager

        function onActiveToplevelChanged() {
            activeWindow = ToplevelManager.activeToplevel?.title ?? "";
            activeWindowClass = ToplevelManager.activeToplevel?.appId ?? "";
            Logger.debug("Focus →", activeWindowClass || "none");
        }
    }

    // --- Dispatch functions ---

    function switchWorkspace(id) {
        Logger.debug("Switching to workspace", id);
        Hyprland.dispatch(`workspace ${id}`);
    }

    function moveWindowToWorkspace(id) {
        Logger.debug("Moving window to workspace", id);
        Hyprland.dispatch(`movetoworkspace ${id}`);
    }

    function logout() {
        Hyprland.dispatch("exit");
    }
}
