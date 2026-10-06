pragma Singleton

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

/**
 * LockConfig - What the lock and the greeter take from the shell: the monitors block of config.json
 * and the recolored wallpapers the shell leaves in its cache.
 *
 * Read only, without the shell's Config: that one writes the defaults when the file is missing, and
 * the greeter runs as another user with its own HOME.
 */
Singleton {
    id: root

    property var monitors: ({})
    // The shell keeps one recolored file per monitor here, named <monitor key>-<hash>
    readonly property string cacheDir: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0].toString().replace("file://", "") + "/bidshell/wallpaper"

    function keyOf(screen) {
        return screen?.model.trim() ?? "";
    }

    // The password field goes on the primary monitor, or on the first one when that is not
    // connected, so there is always exactly one (two monitors of the same model: the first of them)
    function isPrimary(screen) {
        const primary = Object.keys(monitors).find(key => monitors[key]?.primary === true) ?? "";
        const screens = Quickshell.screens;
        return screen === (screens.find(s => keyOf(s) === primary) ?? screens[0]);
    }

    FileView {
        path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/bidshell/config.json"
        blockLoading: true
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            try {
                root.monitors = JSON.parse(text()).monitors ?? {};
            } catch (e) {
                Logger.warn("Lock: config not read:", e);
            }
        }
        onLoadFailed: error => Logger.warn("Lock: config not read:", error)
    }
}
