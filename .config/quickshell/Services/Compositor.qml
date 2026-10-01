pragma Singleton

import QtQuick
import Quickshell
import "../Config"
import "../Utils"

Singleton {
    id: compositor

    // --- Backend loaded by URL (swap this path for a different compositor) ---
    property var backend: null
    property bool isHyprland: backend?.type === "hyprland"
    property bool isNiri: backend?.type === "niri"
    property bool useHyprlandFocusGrab: isHyprland

    Component.onCompleted: {
        var backendPath;
        if (Quickshell.env("NIRI_SOCKET")) {
            backendPath = "Niri/NiriBackend.qml";
        } else if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) {
            backendPath = "Hyprland/HyprlandBackend.qml";
        } else {
            Logger.error("No supported compositor detected (need Hyprland or Niri). Exiting...");
            Qt.callLater(Qt.quit);
            return;
        }

        var comp = Qt.createComponent(backendPath);
        if (comp.status === Component.Ready) {
            backend = comp.createObject(compositor);
        } else {
            Logger.error("Failed to load backend:", comp.errorString());
        }
    }

    // --- Public properties ---

    // { appId, title } of the focused window, title kept live; null when no window has focus
    readonly property var activeWindow: backend?.activeWindow ?? null
    property string focusedMonitorName: backend?.focusedMonitorName ?? ""

    // Every window, each { id (opaque, stable while it exists), appId, title, tag (xdg tag or ""), workspaceId,
    // monitorName, x, y, width, height (global logical px), floating, covers (drawn over every other window on
    // its workspace), focused, hidden (not drawn: unmapped, or a group member behind another) }
    readonly property var windows: backend?.windows ?? []
    // Whether windows carry real positions (x, y), so a map of a workspace can be drawn
    readonly property bool hasWindowGeometry: backend?.hasWindowGeometry ?? false

    // --- Signals ---

    signal workspaceFocusChanged
    signal windowDataUpdated
    signal monitorDataUpdated

    Connections {
        target: backend
        function onWorkspaceFocusChanged() {
            compositor.workspaceFocusChanged();
        }
        function onWindowDataUpdated() {
            compositor.windowDataUpdated();
        }
        function onMonitorDataUpdated() {
            compositor.monitorDataUpdated();
        }
    }

    // --- Function forwarding ---

    // The windows drawn on a workspace
    function windowsOn(workspaceId) {
        return windows.filter(w => w.workspaceId === workspaceId && !w.hidden);
    }
    // The apps open on a workspace, each { appId, title, tag, count }, most windows first; hidden windows count
    function workspaceApps(workspaceId) {
        const apps = {};
        for (const w of windows.filter(w => w.workspaceId === workspaceId)) {
            const appId = w.appId || "unknown";
            if (!apps[appId])
                apps[appId] = {
                    appId: appId,
                    title: w.title,
                    tag: w.tag,
                    count: 0
                };
            apps[appId].count++;
        }
        return Object.values(apps).sort((a, b) => b.count - a.count);
    }
    // The Wayland toplevel of a window, for a ScreencopyView; null when the backend has none
    function toplevelFor(id) {
        return backend ? backend.toplevelFor(id) : null;
    }
    // The monitor showing a screen, or null: { name, key (its key in config.json: the bare model, "MO34WQC2"),
    // x, y, width, height (logical rect, transform applied, in the windows' global space), scale, transform,
    // reserved [left, top, right, bottom], activeWorkspaceId, specialWorkspaceId (0 when none), hdr }
    function monitorFor(screen) {
        return backend ? backend.monitorFor(screen) : null;
    }
    // The workspace buttons of a screen's bar, in order, each { id, label }. The range set for the
    // monitor in config.json (monitors.<key>.workspaces) is passed on; a backend may ignore it
    function workspaceSlots(screen) {
        const range = Config.options.monitors?.[monitorFor(screen)?.key ?? ""]?.workspaces;
        return backend ? backend.workspaceSlots(screen, range) : [];
    }
    function activeWorkspaceIdForScreen(screen) {
        return backend ? backend.activeWorkspaceIdForScreen(screen) : 1;
    }

    // The keys of the compositor bind with this description, ready to show ("Super Q"); "" when there is none
    function keysFor(description) {
        return (backend?.describedBinds ?? []).find(bind => bind.description === description)?.keys ?? "";
    }

    function getCursorPosition(callback) {
        if (backend)
            backend.getCursorPosition(callback);
    }
    function setMonitorColorManagement(name, preset) {
        if (backend)
            backend.setMonitorColorManagement(name, preset);
    }

    // screen is the one the switch is asked from: with per-output desktops (KWin) it says which output switches
    function switchWorkspace(id, screen) {
        if (backend)
            backend.switchWorkspace(id, screen);
    }
    function focusWindow(id) {
        if (backend)
            backend.focusWindow(id);
    }
    // Re-reads the windows now: Hyprland sends no event when a layout moves or resizes them
    function refreshWindows() {
        if (backend)
            backend.refreshWindows();
    }
    function logout() {
        if (backend)
            backend.logout();
    }
}
