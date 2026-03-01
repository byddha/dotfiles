import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

QtObject {
    id: backend

    property string type: "niri"
    property bool isHyprland: false

    property var workspaces: []
    property int activeWorkspace: 1
    property string focusedMonitorName: ""
    property int focusedMonitorId: -1

    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var monitors: []

    signal workspaceFocusChanged()
    signal windowDataUpdated()
    signal monitorDataUpdated()

    // --- Internal state ---

    property var _workspacesRaw: []
    property var _monitorsRaw: ({})
    property var _monitorNameToId: ({})
    property bool _pendingFullUpdate: false

    Component.onCompleted: {
        Logger.info("Running on Niri");
        updateAllData();
        _eventStream.running = true;
    }

    // --- Data fetching ---

    function updateAllData() {
        // Chain: workspaces first, then windows + outputs (they need workspace data)
        _pendingFullUpdate = true;
        _getWorkspaces.running = true;
    }

    function updateWindowList() {
        _getWindows.running = true;
    }

    function updateMonitorData() {
        _getOutputs.running = true;
    }

    property var _wsProc: Process {
        id: _getWorkspaces
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            id: _wsCollector
            onStreamFinished: {
                try {
                    backend._workspacesRaw = JSON.parse(_wsCollector.text);
                    backend._processWorkspaces();
                } catch (e) {
                    Logger.error("Failed to parse niri workspaces:", e);
                }

                if (backend._pendingFullUpdate) {
                    backend._pendingFullUpdate = false;
                    _getWindows.running = true;
                    _getOutputs.running = true;
                }
            }
        }
    }

    property var _winProc: Process {
        id: _getWindows
        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector {
            id: _winCollector
            onStreamFinished: {
                try {
                    const raw = JSON.parse(_winCollector.text);
                    backend._processWindows(raw);
                } catch (e) {
                    Logger.error("Failed to parse niri windows:", e);
                }
            }
        }
    }

    property var _outProc: Process {
        id: _getOutputs
        command: ["niri", "msg", "--json", "outputs"]
        stdout: StdioCollector {
            id: _outCollector
            onStreamFinished: {
                try {
                    backend._monitorsRaw = JSON.parse(_outCollector.text);
                    backend._processMonitors();
                } catch (e) {
                    Logger.error("Failed to parse niri outputs:", e);
                }
            }
        }
    }

    // --- Event stream ---

    property var _evProc: Process {
        id: _eventStream
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    backend._handleEvent(JSON.parse(data));
                } catch (e) {}
            }
        }
        onExited: (exitCode, exitStatus) => {
            Logger.warn("Niri event stream exited, reconnecting...");
            Qt.callLater(() => { _eventStream.running = true; });
        }
    }

    // --- Data processing ---

    function _processWorkspaces() {
        workspaces = _workspacesRaw.map(ws => ({
            id: ws.id,
            idx: ws.idx,
            name: ws.name ?? "",
            output: ws.output ?? "",
            is_active: ws.is_active ?? false,
            is_focused: ws.is_focused ?? false
        }));

        const focused = _workspacesRaw.find(ws => ws.is_focused);
        if (focused) {
            activeWorkspace = focused.id;
            if (focused.output && _monitorNameToId[focused.output] !== undefined) {
                focusedMonitorName = focused.output;
                focusedMonitorId = _monitorNameToId[focused.output];
            }
        }

        _updateMonitorActiveWorkspaces();
        workspaceFocusChanged();
        Logger.debug("Workspaces updated:", workspaces.length);
    }

    function _processWindows(raw) {
        windowList = raw.map(w => _normalizeWindow(w));
        _rebuildWindowMaps();
        windowDataUpdated();
        Logger.debug("Windows updated:", windowList.length);
    }

    function _processMonitors() {
        const names = Object.keys(_monitorsRaw);
        const nameToId = {};
        monitors = names.map((name, idx) => {
            nameToId[name] = idx;
            const out = _monitorsRaw[name];
            const logical = out.logical ?? {};
            return {
                name: name,
                id: idx,
                x: logical.x ?? 0,
                y: logical.y ?? 0,
                width: logical.width ?? 0,
                height: logical.height ?? 0,
                scale: logical.scale ?? 1.0,
                activeWorkspace: { id: _getActiveWorkspaceForOutput(name) },
                transform: _mapTransform(logical.transform),
                reserved: [0, 0, 0, 0],
                colorManagementPreset: ""
            };
        });

        _monitorNameToId = nameToId;

        const focused = _workspacesRaw.find(ws => ws.is_focused);
        if (focused?.output && nameToId[focused.output] !== undefined) {
            focusedMonitorName = focused.output;
            focusedMonitorId = nameToId[focused.output];
        }

        monitorDataUpdated();
        Logger.debug("Monitors updated:", monitors.length, "displays");
    }

    function _normalizeWindow(win) {
        const ws = _workspacesRaw.find(w => w.id === win.workspace_id);
        const monitorId = ws?.output ? (_monitorNameToId[ws.output] ?? -1) : -1;
        return {
            address: "niri-" + win.id,
            class: win.app_id ?? "",
            title: win.title ?? "",
            xdgTag: "",
            xwayland: false,
            workspace: { id: win.workspace_id },
            monitor: monitorId,
            at: [0, 0],
            size: win.layout?.window_size ?? [0, 0],
            floating: win.is_floating ?? false,
            fullscreen: 0,
            pinned: false,
            focusHistoryID: -(win.focus_timestamp ?? 0),
            _niriId: win.id
        };
    }

    function _rebuildWindowMaps() {
        const byAddr = {};
        for (let i = 0; i < windowList.length; ++i)
            byAddr[windowList[i].address] = windowList[i];
        windowByAddress = byAddr;
        addresses = windowList.map(w => w.address);
    }

    function _getActiveWorkspaceForOutput(outputName) {
        const ws = _workspacesRaw.find(w => w.output === outputName && w.is_active);
        return ws?.id ?? 1;
    }

    function _updateMonitorActiveWorkspaces() {
        if (monitors.length === 0) return;
        monitors = monitors.map(mon =>
            Object.assign({}, mon, {
                activeWorkspace: { id: _getActiveWorkspaceForOutput(mon.name) }
            })
        );
        monitorDataUpdated();
    }

    readonly property var _transformMap: ({
        "Normal": 0, "90": 1, "180": 2, "270": 3,
        "Flipped": 4, "Flipped90": 5, "Flipped180": 6, "Flipped270": 7
    })

    function _mapTransform(t) {
        if (typeof t === "number") return t;
        return _transformMap[t] ?? 0;
    }

    // --- Event handling ---

    function _handleEvent(event) {
        if (event.WorkspacesChanged) {
            _workspacesRaw = event.WorkspacesChanged.workspaces;
            _processWorkspaces();
        } else if (event.WindowsChanged) {
            _processWindows(event.WindowsChanged.windows);
        } else if (event.WindowOpenedOrChanged) {
            const rawWin = event.WindowOpenedOrChanged.window;
            const normalized = _normalizeWindow(rawWin);
            const idx = windowList.findIndex(w => w._niriId === rawWin.id);
            if (idx >= 0) {
                const newList = [...windowList];
                newList[idx] = normalized;
                windowList = newList;
            } else {
                windowList = [...windowList, normalized];
            }
            _rebuildWindowMaps();
            windowDataUpdated();
        } else if (event.WindowClosed) {
            const addr = "niri-" + event.WindowClosed.id;
            windowList = windowList.filter(w => w.address !== addr);
            _rebuildWindowMaps();
            windowDataUpdated();
        } else if (event.WindowFocusTimestampChanged) {
            const { id, focus_timestamp } = event.WindowFocusTimestampChanged;
            const addr = "niri-" + id;
            const idx = windowList.findIndex(w => w.address === addr);
            if (idx >= 0) {
                const newList = [...windowList];
                newList[idx] = Object.assign({}, newList[idx], {
                    focusHistoryID: -(focus_timestamp ?? 0)
                });
                windowList = newList;
                _rebuildWindowMaps();
                windowDataUpdated();
            }
        }
    }

    // --- Data query functions ---

    function biggestWindowForWorkspace(workspaceId) {
        const windows = windowList.filter(w => w.workspace.id == workspaceId);
        return windows.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    function getWorkspaceApps(workspaceId) {
        const windows = windowList.filter(w => w.workspace.id == workspaceId);
        if (windows.length === 0) return [];

        const classMap = {};
        windows.forEach(win => {
            const windowClass = win.class || "unknown";
            if (!classMap[windowClass]) {
                classMap[windowClass] = {
                    class: windowClass,
                    title: win.title || "",
                    xdgTag: "",
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
        const mon = monitors.find(m => m.name === name);
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
        const appId = toplevel.appId ?? "";
        const title = toplevel.title ?? "";
        return windowList.find(w => w.class === appId && w.title === title) ?? null;
    }

    function getCursorPosition(callback) {
        // Not available via Niri IPC
    }

    function setMonitorColorManagement(name, preset) {
        Logger.debug("setMonitorColorManagement: not supported on Niri");
    }

    // --- Actions ---

    function switchWorkspace(id) {
        const ws = _workspacesRaw.find(w => w.id === id);
        if (!ws) {
            Logger.error("switchWorkspace: unknown workspace id", id);
            return;
        }
        Logger.debug("Switching to workspace", id, "(idx:", ws.idx + ")");
        _actionComponent.createObject(backend, {
            command: ["niri", "msg", "action", "focus-workspace", String(ws.idx)]
        }).running = true;
    }

    function moveWindowToWorkspace(id) {
        const ws = _workspacesRaw.find(w => w.id === id);
        if (!ws) {
            Logger.error("moveWindowToWorkspace: unknown workspace id", id);
            return;
        }
        Logger.debug("Moving window to workspace", id, "(idx:", ws.idx + ")");
        _actionComponent.createObject(backend, {
            command: ["niri", "msg", "action", "move-window-to-workspace", String(ws.idx)]
        }).running = true;
    }

    function logout() {
        _actionComponent.createObject(backend, {
            command: ["niri", "msg", "action", "quit"]
        }).running = true;
    }

    property var _actionComp: Component {
        id: _actionComponent
        Process {
            onExited: destroy()
        }
    }
}
