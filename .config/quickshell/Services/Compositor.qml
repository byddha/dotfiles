pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
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
    readonly property string activeWindow: ToplevelManager.activeToplevel?.title ?? ""
    readonly property string activeWindowClass: ToplevelManager.activeToplevel?.appId ?? ""
    property string focusedMonitorName: backend?.focusedMonitorName ?? ""

    property var windowList: backend?.windowList ?? []
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
    function logout() {
        if (backend)
            backend.logout();
    }
}
