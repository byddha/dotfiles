pragma Singleton

import QtQuick
import Quickshell
import "../Config"
import "../Utils"

/**
 * Compositor - The one way the shell reaches the compositor. Modules use only this; each backend
 * (Services/Hyprland, Services/Niri) implements the same members, with Services/Wayland holding code
 * the Wayland backends share. Two exceptions use Hyprland directly: HyprWhichKey (Hyprland submaps,
 * absent elsewhere) and Components/FocusGrab, activated only when hasFocusGrab.
 */
Singleton {
    id: compositor

    // The first backend whose environment variable is set runs
    readonly property var backends: [["NIRI_SOCKET", "Niri/NiriBackend.qml"], ["HYPRLAND_INSTANCE_SIGNATURE", "Hyprland/HyprlandBackend.qml"]]
    property var backend: null

    Component.onCompleted: {
        const match = backends.find(([variable]) => Quickshell.env(variable));
        if (!match) {
            Logger.error(`No supported compositor detected (none of ${backends.map(([variable]) => variable).join(", ")} is set). Exiting...`);
            Qt.callLater(Qt.quit);
            return;
        }
        const comp = Qt.createComponent(match[1]);
        if (comp.status === Component.Ready)
            backend = comp.createObject(compositor);
        else
            Logger.error("Failed to load backend:", comp.errorString());
    }

    // --- Public properties ---

    // { appId, title } of the focused window, title kept live; null when no window has focus
    readonly property var activeWindow: backend?.activeWindow ?? null
    property string focusedMonitorName: backend?.focusedMonitorName ?? ""

    // Every window, each { id (opaque, stable while it exists), appId, title, tag (xdg tag or ""), workspaceId,
    // monitorName, x, y, width, height (global logical px), floating, covers (drawn over every other window on
    // its workspace), fullscreen (over the whole monitor and every other window, the bar too; maximized is not), focused,
    // hidden (not drawn: unmapped, or a group member behind another) }
    readonly property var windows: backend?.windows ?? []
    // Whether windows carry real positions (x, y), so a map of a workspace can be drawn
    readonly property bool hasWindowGeometry: backend?.hasWindowGeometry ?? false
    // Whether a FocusGrab works: the compositor tells a popup about clicks outside it, so the popup
    // need not cover the screen and take every key
    readonly property bool hasFocusGrab: backend?.hasFocusGrab ?? false
    // QML files the backend draws previews with: a window's (WindowPreview) and a screen's (ScreenSnapshot);
    // "" when it has none
    readonly property string windowPreviewSource: backend?.windowPreviewSource ?? ""
    readonly property string screenSnapshotSource: backend?.screenSnapshotSource ?? ""
    // Whether setHdr can switch a monitor between HDR and SDR
    readonly property bool hasHdrControl: backend?.hasHdrControl ?? false

    // --- Signals ---

    signal windowDataUpdated
    signal monitorDataUpdated

    Connections {
        target: backend
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
    function setHdr(monitorName, on) {
        if (backend)
            backend.setHdr(monitorName, on);
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
