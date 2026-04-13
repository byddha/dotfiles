pragma Singleton

import QtQuick
import Quickshell
import "../../Services"
import "../../Utils"

Singleton {
    id: root

    function poweroff() {
        Logger.info("PowerActions: poweroff");
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function reboot() {
        Logger.info("PowerActions: reboot");
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function suspend() {
        Logger.info("PowerActions: suspend");
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function logout() {
        Logger.info("PowerActions: logout");
        Compositor.logout();
    }

    function lock() {
        Logger.info("PowerActions: lock");
        SessionLock.lock();
    }
}
