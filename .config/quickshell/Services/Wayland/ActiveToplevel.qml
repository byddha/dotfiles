import QtQuick
import Quickshell.Wayland

QtObject {
    readonly property var window: ToplevelManager.activeToplevel ? {
        appId: ToplevelManager.activeToplevel.appId,
        title: ToplevelManager.activeToplevel.title
    } : null
}
