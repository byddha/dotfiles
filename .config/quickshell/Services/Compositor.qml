pragma Singleton

import QtQuick
import Quickshell
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

    property var workspaces: backend?.workspaces ?? []
    // { appId, title } of the focused window, title kept live; null when no window has focus
    readonly property var activeWindow: backend?.activeWindow ?? null
    property string focusedMonitorName: backend?.focusedMonitorName ?? ""

    property var windowList: backend?.windowList ?? []
    // Whether windows carry real positions (`at`, `size`), so a map of a workspace can be drawn
    readonly property bool hasWindowGeometry: backend?.hasWindowGeometry ?? false
    property var monitors: backend?.monitors ?? []

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

    function getWorkspaceApps(workspaceId) {
        return backend ? backend.getWorkspaceApps(workspaceId) : [];
    }
    // The Wayland toplevel of a window, for a ScreencopyView; null when the backend has none
    function toplevelFor(address) {
        return backend ? backend.toplevelFor(address) : null;
    }
    // Whether the compositor draws this window over every other one on its workspace (a
    // fullscreen or maximized window it handles itself; a scrolling layout keeps it a column)
    function coversWorkspace(window) {
        return backend ? backend.coversWorkspace(window) : false;
    }
    // The windows on a workspace that are drawn there (not unmapped, not a hidden group member)
    function shownWindows(workspaceId) {
        return backend ? backend.shownWindows(workspaceId) : [];
    }
    function monitorForScreen(screen) {
        return backend ? backend.monitorForScreen(screen) : null;
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

    function switchWorkspace(id) {
        if (backend)
            backend.switchWorkspace(id);
    }
    function focusWindow(address) {
        if (backend)
            backend.focusWindow(address);
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
