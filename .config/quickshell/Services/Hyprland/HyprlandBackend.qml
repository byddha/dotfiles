import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../Utils"

QtObject {
    id: backend

    property string type: "hyprland"

    property var workspaces: []
    property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""

    // lastIpcObject holds the same JSON as `hyprctl clients/monitors -j`. Quickshell fills it
    // shortly after startup and on refreshToplevels()/refreshMonitors(); each update
    // re-evaluates these bindings through lastIpcObjectChanged.
    readonly property var windowList: Hyprland.toplevels.values.map(t => t.lastIpcObject).filter(w => w?.address)
    readonly property var monitors: Hyprland.monitors.values.map(m => m.lastIpcObject).filter(m => m?.name)

    signal workspaceFocusChanged
    signal windowDataUpdated
    signal monitorDataUpdated

    // A refresh updates each toplevel separately, so coalesce the per-object binding updates.
    onWindowListChanged: Qt.callLater(_emitWindowData)
    onMonitorsChanged: Qt.callLater(_emitMonitorData)

    function _emitWindowData() {
        windowDataUpdated();
    }

    function _emitMonitorData() {
        monitorDataUpdated();
    }

    // Compositor.qml only loads this backend when HYPRLAND_INSTANCE_SIGNATURE is set.
    Component.onCompleted: workspaces = Hyprland.workspaces.values

    // --- Data query functions ---

    function getWorkspaceApps(workspaceId) {
        const windowsInWorkspace = backend.windowList.filter(w => w.workspace.id == workspaceId);

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
        const mon = backend.monitors.find(m => m.name === name);
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

    function hasFullscreenOnScreen(screen) {
        const mon = backend.monitors.find(m => m.name === screen?.name);
        if (!mon)
            return false;
        // An open special workspace is shown over the regular one (its id is 0 when none is open)
        const workspaceId = mon.specialWorkspace?.id || mon.activeWorkspace?.id;
        // fullscreen is a bit mask: 1 maximized, 2 fullscreen
        return backend.windowList.some(w => (w.fullscreen & 2) && w.mapped && !w.hidden && w.workspace?.id === workspaceId);
    }

    function getCursorPosition(callback) {
        const proc = cursorPosComponent.createObject(backend, {
            callback: callback
        });
        proc.running = true;
    }

    property var _cursorPosComponent: Component {
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
        const proc = cmComponent.createObject(backend, {
            command: ["hyprctl", "eval", `cmd.run("monitor cm ${name} ${preset}")`]
        });
        proc.running = true;
    }

    property var _cmComponent: Component {
        id: cmComponent
        Process {
            // `monitor cm` emits no event, so pull the new colorManagementPreset for Hdr.
            onExited: {
                Hyprland.refreshMonitors();
                destroy();
            }
        }
    }

    // Filter as in DankMaterialShell. windowtitle is skipped: titles come live from ToplevelManager.
    readonly property var _toplevelEvents: ["openwindow", "closewindow", "movewindow", "movewindowv2", "activewindow", "activewindowv2", "changefloatingmode", "fullscreen", "moveintogroup", "moveoutofgroup"]
    readonly property var _monitorEvents: ["workspace", "workspacev2", "focusedmon", "focusedmonv2", "activespecial", "activespecialv2", "moveworkspace", "moveworkspacev2", "monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2", "configreloaded"]
    property bool _toplevelsDirty: false
    property bool _monitorsDirty: false

    // Hyprland sends most events twice (v1 + v2) in one burst; callLater runs the refresh once.
    function _flushRefresh() {
        if (_toplevelsDirty)
            Hyprland.refreshToplevels();
        if (_monitorsDirty)
            Hyprland.refreshMonitors();
        _toplevelsDirty = false;
        _monitorsDirty = false;
    }

    // --- Connections ---

    property var _hyprlandConnections: Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            backend.workspaceFocusChanged();
        }

        function onFocusedMonitorChanged() {
            backend.focusedMonitorName = Hyprland.focusedMonitor?.name ?? "";
            backend.workspaceFocusChanged();
        }

        function onRawEvent(event) {
            const isMonitorEvent = backend._monitorEvents.includes(event.name);
            if (!isMonitorEvent && !backend._toplevelEvents.includes(event.name))
                return;
            // Workspace switches also move which windows are visible, so they refresh both.
            backend._toplevelsDirty = true;
            if (isMonitorEvent)
                backend._monitorsDirty = true;
            Qt.callLater(backend._flushRefresh);
        }
    }

    // --- Dispatch functions ---

    function switchWorkspace(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    function logout() {
        Hyprland.dispatch("hl.dsp.exit()");
    }
}
