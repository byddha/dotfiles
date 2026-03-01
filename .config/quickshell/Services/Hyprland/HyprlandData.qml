// DEPRECATED: thin redirect to Compositor. Will be removed after all consumers are migrated.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    property var windowList: Compositor.windowList
    property var windowByAddress: Compositor.windowByAddress
    property var addresses: Compositor.addresses
    property var monitors: Compositor.monitors

    function biggestWindowForWorkspace(workspaceId) { return Compositor.biggestWindowForWorkspace(workspaceId) }
    function getWorkspaceApps(workspaceId) { return Compositor.getWorkspaceApps(workspaceId) }
}
