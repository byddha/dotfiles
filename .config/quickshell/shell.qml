import QtQuick
import Quickshell
import "Config"
import "Services"
import "Utils"
import "Components"
import "Modules/IPC"
import "Modules/Notifications"
import "Modules/HyprWhichKey"
import "Modules/Overview"
import "Modules/Bar"
import "Modules/Sidebar"
import "Modules/OSD"
import "Modules/GameLauncher"
import "Modules/RegionSelector"

ShellRoot {
    id: root

    Component.onCompleted: {
        Config.init();
        Theme.init();
        Settings.init();
        Icons.init();
        WeatherService.init();
        Logger.info("Components initialized");
    }

    // IPCManager must be outside LazyLoader to register properly
    IPCManager {
        id: ipcManager
    }

    Bar {
        id: bar
    }

    HyprWhichKey {
        id: hyprWhichKey
    }

    Notifications {
        id: notifications
    }

    Overview {
        id: overview
    }

    Sidebar {
        id: sidebar
    }

    OSD {
        id: osd
    }

    GameLauncher {
        id: gameLauncher
    }

    RegionSelector {
        id: regionSelector
    }
}
