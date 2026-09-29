import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

QtObject {
    id: backend

    property string type: "niri"

    property var workspaces: []
    property string focusedMonitorName: ""

    property var windowList: []
    property var monitors: []

    signal workspaceFocusChanged
    signal windowDataUpdated
    signal monitorDataUpdated

    // --- Internal state ---

    property var _workspacesRaw: []
    property var _monitorsRaw: ({})
    property var _monitorNameToId: ({})
    property bool _pendingFullUpdate: false

    Component.onCompleted: {
        updateAllData();
        eventStream.running = true;
    }

    // --- Data fetching ---

    function updateAllData() {
        // Chain: workspaces first, then windows + outputs (they need workspace data)
        _pendingFullUpdate = true;
        getWorkspaces.running = true;
    }

    function updateWindowList() {
        getWindows.running = true;
    }

    function updateMonitorData() {
        getOutputs.running = true;
    }

    property var _wsProc: Process {
        id: getWorkspaces
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            id: wsCollector
            onStreamFinished: {
                try {
                    backend._workspacesRaw = JSON.parse(wsCollector.text);
                    backend._processWorkspaces();
                } catch (e) {
                    Logger.error("Failed to parse niri workspaces:", e);
                }

                if (backend._pendingFullUpdate) {
                    backend._pendingFullUpdate = false;
                    getWindows.running = true;
                    getOutputs.running = true;
                }
            }
        }
    }

    property var _winProc: Process {
        id: getWindows
        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector {
            id: winCollector
            onStreamFinished: {
                try {
                    const raw = JSON.parse(winCollector.text);
                    backend._processWindows(raw);
                } catch (e) {
                    Logger.error("Failed to parse niri windows:", e);
                }
            }
        }
    }

    property var _outProc: Process {
        id: getOutputs
        command: ["niri", "msg", "--json", "outputs"]
        stdout: StdioCollector {
            id: outCollector
            onStreamFinished: {
                try {
                    backend._monitorsRaw = JSON.parse(outCollector.text);
                    backend._processMonitors();
                } catch (e) {
                    Logger.error("Failed to parse niri outputs:", e);
                }
            }
        }
    }

    // --- Event stream ---

    property var _evProc: Process {
        id: eventStream
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
            Qt.callLater(() => {
                eventStream.running = true;
            });
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
        if (focused?.output && _monitorNameToId[focused.output] !== undefined)
            focusedMonitorName = focused.output;

        _updateMonitorActiveWorkspaces();
        workspaceFocusChanged();
    }

    function _processWindows(raw) {
        windowList = raw.map(w => _normalizeWindow(w));
        windowDataUpdated();
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
                activeWorkspace: {
                    id: _getActiveWorkspaceForOutput(name)
                },
                transform: _mapTransform(logical.transform),
                reserved: [0, 0, 0, 0],
                colorManagementPreset: ""
            };
        });

        _monitorNameToId = nameToId;

        const focused = _workspacesRaw.find(ws => ws.is_focused);
        if (focused?.output && nameToId[focused.output] !== undefined)
            focusedMonitorName = focused.output;

        monitorDataUpdated();
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
            workspace: {
                id: win.workspace_id
            },
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

    function _getActiveWorkspaceForOutput(outputName) {
        const ws = _workspacesRaw.find(w => w.output === outputName && w.is_active);
        return ws?.id ?? 1;
    }

    function _updateMonitorActiveWorkspaces() {
        if (monitors.length === 0)
            return;
        monitors = monitors.map(mon => Object.assign({}, mon, {
                activeWorkspace: {
                    id: _getActiveWorkspaceForOutput(mon.name)
                }
            }));
        monitorDataUpdated();
    }

    readonly property var _transformMap: ({
            "Normal": 0,
            "90": 1,
            "180": 2,
            "270": 3,
            "Flipped": 4,
            "Flipped90": 5,
            "Flipped180": 6,
            "Flipped270": 7
        })

    function _mapTransform(t) {
        if (typeof t === "number")
            return t;
        return _transformMap[t] ?? 0;
    }

    // --- Event handling ---

    function _handleEvent(event) {
        if (event.WorkspacesChanged) {
            _workspacesRaw = event.WorkspacesChanged.workspaces;
            _processWorkspaces();
        } else if (event.WorkspaceActivated) {
            _handleWorkspaceActivated(event.WorkspaceActivated);
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
            windowDataUpdated();
        } else if (event.WindowClosed) {
            const addr = "niri-" + event.WindowClosed.id;
            windowList = windowList.filter(w => w.address !== addr);
            windowDataUpdated();
        } else if (event.WindowFocusTimestampChanged) {
            const {
                id,
                focus_timestamp
            } = event.WindowFocusTimestampChanged;
            const addr = "niri-" + id;
            const idx = windowList.findIndex(w => w.address === addr);
            if (idx >= 0) {
                const newList = [...windowList];
                newList[idx] = Object.assign({}, newList[idx], {
                    focusHistoryID: -(focus_timestamp ?? 0)
                });
                windowList = newList;
                windowDataUpdated();
            }
        }
    }

    function _handleWorkspaceActivated(data) {
        const activated = _workspacesRaw.find(w => w.id === data.id);
        if (!activated)
            return;

        const outputName = activated.output ?? "";
        _workspacesRaw = _workspacesRaw.map(ws => Object.assign({}, ws, {
                is_active: outputName && ws.output === outputName ? ws.id === data.id : ws.is_active,
                is_focused: data.focused ? ws.id === data.id : ws.is_focused
            }));
        _processWorkspaces();
    }

    // --- Data query functions ---

    function getWorkspaceApps(workspaceId) {
        const windows = windowList.filter(w => w.workspace.id == workspaceId);
        if (windows.length === 0)
            return [];

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
        if (!mon)
            return null;
        return {
            name: mon.name,
            model: screen?.model ?? "",
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

    // Niri's IPC does not list binds, so no bar item shows keys there
    readonly property var describedBinds: []

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
        actionComponent.createObject(backend, {
            command: ["niri", "msg", "action", "focus-workspace", String(ws.idx)]
        }).running = true;
    }

    function focusWindow(address) {
        actionComponent.createObject(backend, {
            command: ["niri", "msg", "action", "focus-window", "--id", address.replace("niri-", "")]
        }).running = true;
    }

    // The event stream keeps the windows current
    function refreshWindows() {
    }

    function logout() {
        actionComponent.createObject(backend, {
            command: ["niri", "msg", "action", "quit"]
        }).running = true;
    }

    property var _actionComp: Component {
        id: actionComponent
        Process {
            onExited: destroy()
        }
    }
}
