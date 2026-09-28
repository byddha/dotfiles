pragma Singleton

import QtQuick
import Quickshell
import "../../Services"

Singleton {
    id: root

    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function logout() {
        Compositor.logout();
    }

    // Whatever locker listens for the session's Lock signal (hypridle's lock_cmd)
    function lock() {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }
}
