import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

QtObject {
    id: backend

    readonly property bool hasWindowGeometry: true
    readonly property bool hasFocusGrab: false
    readonly property bool hasHdrControl: false
    readonly property string windowPreviewSource: ""
    readonly property string screenSnapshotSource: ""
    readonly property var describedBinds: []

    // The last state kwin_bridge.py relayed from the KWin script (bidshell.js)
    property var _state: ({
            windows: [],
            outputs: [],
            desktopCount: 0,
            activeOutput: "",
            perOutputDesktops: false
        })

    readonly property string focusedMonitorName: _state.activeOutput
    readonly property var activeWindow: {
        const active = _state.windows.find(w => w.active);
        return active ? {
            appId: active.appId,
            title: active.title
        } : null;
    }
    readonly property var windows: _state.windows.map(w => ({
                id: w.id,
                appId: w.appId,
                title: w.title,
                tag: "",
                // A window on every desktop counts as on the one its output shows
                workspaceId: w.onAllDesktops ? _outputNamed(w.output).desktop : w.desktops[0],
                monitorName: w.output,
                x: w.geometry[0],
                y: w.geometry[1],
                width: w.geometry[2],
                height: w.geometry[3],
                // KWin does not tell tiled windows from floating ones, so none is raised above the rest
                floating: false,
                covers: w.fullScreen,
                focused: w.active,
                hidden: w.minimized
            }))

    signal windowDataUpdated
    signal monitorDataUpdated

    function _outputNamed(name) {
        return _state.outputs.find(o => o.name === name);
    }

    function monitorFor(screen) {
        const output = _outputNamed(screen?.name);
        if (!output)
            return null;
        const [x, y, width, height] = output.geometry;
        const [areaX, areaY, areaWidth, areaHeight] = output.area;
        return {
            name: output.name,
            key: output.key,
            x: x,
            y: y,
            width: width,
            height: height,
            scale: output.scale,
            // KWin's geometry already has the rotation applied
            transform: 0,
            reserved: [areaX - x, areaY - y, x + width - areaX - areaWidth, y + height - areaY - areaHeight],
            activeWorkspaceId: output.desktop,
            specialWorkspaceId: 0,
            hdr: false
        };
    }

    property bool _warnedMissingDesktops: false

    // With desktops per output, the configured range; otherwise every screen switches together, so every bar shows them all
    function workspaceSlots(screen, range) {
        const count = _state.desktopCount;
        const first = _state.perOutputDesktops && range ? range[0] : 1;
        const last = _state.perOutputDesktops && range ? range[1] : count;
        if (last > count && count > 0 && !_warnedMissingDesktops) {
            _warnedMissingDesktops = true;
            Logger.warn(`config.json names desktop ${last}, KWin has ${count}; the bar skips the missing ones`);
        }
        const slots = [];
        for (let id = first; id <= Math.min(last, count); id++)
            slots.push({
                id: id,
                label: id
            });
        return slots;
    }

    function activeWorkspaceIdForScreen(screen) {
        return _outputNamed(screen?.name)?.desktop ?? 1;
    }

    function switchWorkspace(id, screen) {
        _send({
            action: "switch",
            desktop: id,
            output: _state.perOutputDesktops ? screen.name : null
        });
    }

    function focusWindow(id) {
        _send({
            action: "focus",
            id: id
        });
    }

    // The KWin script sends every move and resize
    function refreshWindows() {
    }

    function getCursorPosition(callback) {
    }

    function setHdr(monitorName, on) {
    }

    function logout() {
        _send({
            action: "logout"
        });
    }

    function _send(command) {
        _bridge.write(JSON.stringify(command) + "\n");
    }

    property var _bridge: Process {
        command: ["python3", Quickshell.shellPath("Services/KWin/kwin_bridge.py")]
        running: true
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => {
                const outputsBefore = JSON.stringify(backend._state.outputs);
                backend._state = JSON.parse(data);
                backend.windowDataUpdated();
                if (JSON.stringify(backend._state.outputs) !== outputsBefore)
                    backend.monitorDataUpdated();
            }
        }
        onExited: (exitCode, exitStatus) => {
            Logger.warn(`KWin bridge exited (${exitCode}), restarting in a second`);
            backend._restart.start();
        }
    }

    // A second's pause, so a bridge that fails at once does not spin
    property var _restart: Timer {
        interval: 1000
        onTriggered: backend._bridge.running = true
    }
}
