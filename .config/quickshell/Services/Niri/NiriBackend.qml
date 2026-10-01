import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"
import "../Wayland"

QtObject {
    id: backend

    property string type: "niri"
    // Its windows have no positions yet (see _normalizeWindow)
    readonly property bool hasWindowGeometry: false

    property string focusedMonitorName: ""
    readonly property var activeWindow: _activeToplevel.window
    property var _activeToplevel: ActiveToplevel {}

    property var windows: []
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
        const focused = _workspacesRaw.find(ws => ws.is_focused);
        if (focused?.output && _monitorNameToId[focused.output] !== undefined)
            focusedMonitorName = focused.output;

        _updateMonitorActiveWorkspaces();
        workspaceFocusChanged();
    }

    function _processWindows(raw) {
        windows = raw.map(w => _normalizeWindow(w));
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
                reserved: [0, 0, 0, 0]
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
        const size = win.layout?.window_size ?? [0, 0];
        return {
            id: "niri-" + win.id,
            appId: win.app_id ?? "",
            title: win.title ?? "",
            tag: "",
            workspaceId: win.workspace_id,
            monitorName: ws?.output ?? "",
            x: 0,
            y: 0,
            width: size[0],
            height: size[1],
            floating: win.is_floating ?? false,
            covers: false,
            focused: win.is_focused ?? false,
            hidden: false
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
            const window = _normalizeWindow(event.WindowOpenedOrChanged.window);
            const others = window.focused ? windows.map(w => Object.assign({}, w, {
                    focused: false
                })) : windows;
            const idx = others.findIndex(w => w.id === window.id);
            windows = idx >= 0 ? others.map((w, i) => i === idx ? window : w) : [...others, window];
            windowDataUpdated();
        } else if (event.WindowClosed) {
            const id = "niri-" + event.WindowClosed.id;
            windows = windows.filter(w => w.id !== id);
            windowDataUpdated();
        } else if (event.WindowFocusChanged) {
            const id = "niri-" + event.WindowFocusChanged.id;
            windows = windows.map(w => Object.assign({}, w, {
                    focused: w.id === id
                }));
            windowDataUpdated();
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

    function toplevelFor(id) {
        return null;
    }

    function monitorFor(screen) {
        const mon = monitors.find(m => m.name === screen?.name);
        if (!mon)
            return null;
        return {
            name: mon.name,
            key: screen.model,
            x: mon.x,
            y: mon.y,
            width: mon.width,
            height: mon.height,
            scale: mon.scale,
            transform: mon.transform,
            reserved: mon.reserved,
            activeWorkspaceId: mon.activeWorkspace.id,
            specialWorkspaceId: 0,
            hdr: false
        };
    }

    // The output's own workspaces; the configured range does not apply
    function workspaceSlots(screen, range) {
        return _workspacesRaw.filter(ws => ws.output === screen?.name).sort((a, b) => (a.idx ?? 0) - (b.idx ?? 0)).map(ws => ({
                    id: ws.id,
                    label: ws.idx ?? ws.id
                }));
    }

    function activeWorkspaceIdForScreen(screen) {
        return monitorFor(screen)?.activeWorkspaceId ?? 1;
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

    function switchWorkspace(id, screen) {
        const ws = _workspacesRaw.find(w => w.id === id);
        if (!ws) {
            Logger.error("switchWorkspace: unknown workspace id", id);
            return;
        }
        actionComponent.createObject(backend, {
            command: ["niri", "msg", "action", "focus-workspace", String(ws.idx)]
        }).running = true;
    }

    function focusWindow(id) {
        actionComponent.createObject(backend, {
            command: ["niri", "msg", "action", "focus-window", "--id", id.replace("niri-", "")]
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
