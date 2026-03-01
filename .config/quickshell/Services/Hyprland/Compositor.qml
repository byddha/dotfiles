pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../Utils"

Singleton {
    id: compositor

    property string type: "hyprland"
    property bool isHyprland: true

    property var workspaces: []
    property int activeWorkspace: 1
    property string activeWindow: ""
    property string activeWindowClass: ""
    property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""
    property int focusedMonitorId: Hyprland.focusedMonitor?.id ?? -1

    signal workspaceFocusChanged()

    Component.onCompleted: {
        detectCompositor();
    }

    function detectCompositor() {
        try {
            if (Hyprland.eventSocketPath) {
                initHyprland();
                Logger.info("Running on Hyprland");
                return;
            }
        } catch (e) {}

        Logger.error("This shell only supports Hyprland. Exiting...");
        Qt.callLater(Qt.quit);
    }

    function initHyprland() {
        updateWorkspaces();
    }

    function updateWorkspaces() {
        workspaces = Hyprland.workspaces.values;
        activeWorkspace = Hyprland.focusedWorkspace?.id ?? 1;
        activeWindow = ToplevelManager.activeToplevel?.title ?? "";
        activeWindowClass = ToplevelManager.activeToplevel?.appId ?? "";
    }

    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            activeWorkspace = Hyprland.focusedWorkspace?.id ?? 1;
            workspaceFocusChanged();
            Logger.debug("Workspace →", activeWorkspace);
        }

        function onFocusedMonitorChanged() {
            focusedMonitorName = Hyprland.focusedMonitor?.name ?? "";
            focusedMonitorId = Hyprland.focusedMonitor?.id ?? -1;
            workspaceFocusChanged();
        }
    }

    Connections {
        target: ToplevelManager

        function onActiveToplevelChanged() {
            activeWindow = ToplevelManager.activeToplevel?.title ?? "";
            activeWindowClass = ToplevelManager.activeToplevel?.appId ?? "";
            Logger.debug("Focus →", activeWindowClass || "none");
        }
    }

    function switchWorkspace(id) {
        Logger.debug("Switching to workspace", id);
        Hyprland.dispatch(`workspace ${id}`);
    }

    function moveWindowToWorkspace(id) {
        Logger.debug("Moving window to workspace", id);
        Hyprland.dispatch(`movetoworkspace ${id}`);
    }

    function logout() {
        Hyprland.dispatch("exit");
    }
}
