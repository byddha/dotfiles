import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../Utils"
import "../Wayland"

QtObject {
    id: backend

    property string type: "hyprland"
    readonly property bool hasWindowGeometry: true
    readonly property bool hasFocusGrab: true
    readonly property bool hasHdrControl: true

    property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""
    readonly property var activeWindow: _activeToplevel.window
    property var _activeToplevel: ActiveToplevel {}

    // lastIpcObject holds the same JSON as `hyprctl clients/monitors -j`. Quickshell fills it
    // shortly after startup and on refreshToplevels()/refreshMonitors(); each update
    // re-evaluates these bindings through lastIpcObjectChanged.
    readonly property var monitors: Hyprland.monitors.values.map(m => m.lastIpcObject).filter(m => m?.name)
    readonly property var windows: Hyprland.toplevels.values.map(t => t.lastIpcObject).filter(w => w?.address).map(w => ({
                id: w.address,
                appId: w.class,
                title: w.title,
                tag: w.xdgTag || "",
                workspaceId: w.workspace.id,
                monitorName: monitors.find(m => m.id === w.monitor)?.name ?? "",
                x: w.at[0],
                y: w.at[1],
                width: w.size[0],
                height: w.size[1],
                floating: w.floating,
                // fullscreen: 1 = maximized, 2 = fullscreen. The default handler draws it over the rest; a layout
                // that handles it itself (scrolling) keeps it beside the others
                covers: w.fullscreen > 0 && w.fullscreenHandler === "default",
                focused: w.focusHistoryID === 0,
                // Unmapped windows and the hidden members of a group are not drawn
                hidden: !w.mapped || w.hidden
            }))

    signal workspaceFocusChanged
    signal windowDataUpdated
    signal monitorDataUpdated

    // A refresh updates each toplevel separately, so coalesce the per-object binding updates.
    onWindowsChanged: Qt.callLater(_emitWindowData)
    onMonitorsChanged: Qt.callLater(_emitMonitorData)

    function _emitWindowData() {
        windowDataUpdated();
    }

    function _emitMonitorData() {
        monitorDataUpdated();
    }

    // Main-map binds that have a description, as { description, keys } with keys ready to show
    // ("Super Shift Q"). With a Lua config the dispatcher reads "__lua <n>", so the description is
    // the only way to tell what a bind does. Read again when the config reloads.
    property var describedBinds: []

    property var _bindsReader: Process {
        command: ["hyprctl", "binds", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: backend.describedBinds = JSON.parse(text).filter(b => b.submap === "" && b.description).map(b => ({
                        description: b.description,
                        keys: backend.keysLabel(b.modmask, b.key)
                    }))
        }
    }

    function keysLabel(modmask, key) {
        // Hyprland's modifier bits, shown in this order
        const modifiers = [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]].filter(([bit]) => modmask & bit).map(([, name]) => name);
        const label = key.length === 1 ? key.toUpperCase() : key.charAt(0).toUpperCase() + key.slice(1).toLowerCase();
        return [...modifiers, label].join(" ");
    }

    // --- Data query functions ---

    function toplevelFor(id) {
        return Hyprland.toplevels.values.find(t => `0x${t.address}` === id)?.wayland ?? null;
    }

    function monitorFor(screen) {
        const mon = backend.monitors.find(m => m.name === screen?.name);
        if (!mon)
            return null;
        // width/height are the mode's pixels; an odd transform turns the monitor a quarter
        const turned = (mon.transform ?? 0) % 2 === 1;
        return {
            name: mon.name,
            key: screen.model,
            x: mon.x,
            y: mon.y,
            width: (turned ? mon.height : mon.width) / mon.scale,
            height: (turned ? mon.width : mon.height) / mon.scale,
            scale: mon.scale,
            transform: mon.transform ?? 0,
            reserved: mon.reserved ?? [0, 0, 0, 0],
            activeWorkspaceId: mon.activeWorkspace?.id ?? 1,
            specialWorkspaceId: mon.specialWorkspace?.id ?? 0,
            hdr: mon.colorManagementPreset === "hdr"
        };
    }

    // The monitor's configured range; none configured, no buttons
    function workspaceSlots(screen, range) {
        if (!range)
            return [];
        const slots = [];
        for (let id = range[0]; id <= range[1]; id++)
            slots.push({
                id: id,
                label: id
            });
        return slots;
    }

    function activeWorkspaceIdForScreen(screen) {
        return monitorFor(screen)?.activeWorkspaceId ?? 1;
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

    function setHdr(monitorName, on) {
        const proc = cmComponent.createObject(backend, {
            command: ["hyprctl", "eval", `cmd.run("monitor cm ${monitorName} ${on ? "hdr" : "srgb"}")`]
        });
        proc.running = true;
    }

    property var _cmComponent: Component {
        id: cmComponent
        Process {
            // `monitor cm` emits no event, so the monitors are read again for the new colorManagementPreset
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
            if (event.name === "configreloaded")
                backend._bindsReader.running = true;
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

    function switchWorkspace(id, screen) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    function focusWindow(id) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${id}" })`);
    }

    function refreshWindows() {
        Hyprland.refreshToplevels();
    }

    function logout() {
        Hyprland.dispatch("hl.dsp.exit()");
    }
}
