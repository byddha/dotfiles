pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Utils"

Singleton {
    id: compositor

    // --- Backend loaded by URL (swap this path for a different compositor) ---
    property var backend: null

    Component.onCompleted: {
        var comp = Qt.createComponent("Hyprland/HyprlandBackend.qml");
        if (comp.status === Component.Ready) {
            backend = comp.createObject(compositor);
        } else {
            Logger.error("Failed to load backend:", comp.errorString());
        }
    }

    // --- Public properties ---

    property string type: backend?.type ?? ""
    property bool isHyprland: backend?.isHyprland ?? false

    property var workspaces: backend?.workspaces ?? []
    property int activeWorkspace: backend?.activeWorkspace ?? 1
    property string activeWindow: ""
    property string activeWindowClass: ""
    property string focusedMonitorName: backend?.focusedMonitorName ?? ""
    property int focusedMonitorId: backend?.focusedMonitorId ?? -1

    property var windowList: backend?.windowList ?? []
    property var addresses: backend?.addresses ?? []
    property var windowByAddress: backend?.windowByAddress ?? ({})
    property var monitors: backend?.monitors ?? []

    // --- Signals ---

    signal workspaceFocusChanged()
    signal windowDataUpdated()
    signal monitorDataUpdated()

    Connections {
        target: backend
        function onWorkspaceFocusChanged() { compositor.workspaceFocusChanged() }
        function onWindowDataUpdated() { compositor.windowDataUpdated() }
        function onMonitorDataUpdated() { compositor.monitorDataUpdated() }
    }

    // --- Wayland toplevel tracking (compositor-generic) ---

    Connections {
        target: ToplevelManager

        function onActiveToplevelChanged() {
            activeWindow = ToplevelManager.activeToplevel?.title ?? "";
            activeWindowClass = ToplevelManager.activeToplevel?.appId ?? "";
            Logger.debug("Focus →", activeWindowClass || "none");
        }
    }

    // --- Function forwarding ---

    function updateWindowList() { if (backend) backend.updateWindowList() }
    function updateMonitorData() { if (backend) backend.updateMonitorData() }
    function updateAllData() { if (backend) backend.updateAllData() }

    function biggestWindowForWorkspace(workspaceId) { return backend ? backend.biggestWindowForWorkspace(workspaceId) : null }
    function getWorkspaceApps(workspaceId) { return backend ? backend.getWorkspaceApps(workspaceId) : [] }
    function monitorForScreen(screen) { return backend ? backend.monitorForScreen(screen) : null }
    function activeWorkspaceIdForScreen(screen) { return backend ? backend.activeWorkspaceIdForScreen(screen) : 1 }
    function windowForToplevel(toplevel) { return backend ? backend.windowForToplevel(toplevel) : null }

    function getCursorPosition(callback) { if (backend) backend.getCursorPosition(callback) }
    function setMonitorColorManagement(name, preset) { if (backend) backend.setMonitorColorManagement(name, preset) }

    function switchWorkspace(id) { if (backend) backend.switchWorkspace(id) }
    function moveWindowToWorkspace(id) { if (backend) backend.moveWindowToWorkspace(id) }
    function logout() { if (backend) backend.logout() }
}
