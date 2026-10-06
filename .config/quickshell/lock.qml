import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Modules/Lock"
import "Utils"

/**
 * The lock: a process of its own, so a crash or a reload of the shell never touches it. It locks
 * when it starts and quits once unlocked; hypridle starts it for the session's Lock signal:
 *
 *   scripts/lock                     (hypridle's lock_cmd)
 *   scripts/lock unlock|pause|resume (its IPC, through the script so the path matches)
 */
ShellRoot {
    id: root

    property bool wanted: true
    // Lock-loss retry, as in DankMaterialShell: if the compositor drops or refuses the lock while we
    // still want it, `locked` goes false and back true to ask for a new one
    readonly property int maxRetries: 3
    property int retries: 0
    property bool retryPending: false
    property bool paused: false

    onPausedChanged: Logger.info(paused ? "Lock: wallpaper paused (monitors off)" : "Lock: wallpaper resumed")

    // Quits here too, not only when `locked` turns false: while a retry is pending it already is
    function finish() {
        wanted = false;
        if (!sessionLock.locked)
            Qt.quit();
    }

    // No reload while locked: the files are edited while the lock is up
    Binding {
        target: Quickshell
        property: "watchFiles"
        value: false
    }

    PamAuth {
        id: pamAuth

        onSucceeded: root.finish()
    }

    LockInput {
        id: lockInput
    }

    WlSessionLock {
        id: sessionLock

        locked: root.wanted && !root.retryPending

        onSecureChanged: {
            if (secure)
                root.retries = 0;
        }
        onLockedChanged: {
            if (locked || root.retryPending)
                return;
            if (!root.wanted) {
                Qt.quit();
                return;
            }
            if (root.retries >= root.maxRetries) {
                Logger.error("Lock: the compositor refused the lock", root.maxRetries, "times");
                Qt.exit(1);
                return;
            }
            root.retries++;
            root.retryPending = true;
            retryTimer.restart();
            Logger.warn("Lock: lost, retry", root.retries, "of", root.maxRetries);
        }

        WlSessionLockSurface {
            id: surface

            color: "black"

            LockView {
                anchors.fill: parent
                screen: surface.screen
                auth: pamAuth
                input: lockInput
                playing: !root.paused
            }
        }
    }

    Timer {
        id: retryTimer

        interval: 1000
        onTriggered: root.retryPending = false
    }

    IpcHandler {
        target: "lock"

        function unlock(): void {
            root.finish();
        }

        function pause(): void {
            root.paused = true;
        }

        function resume(): void {
            root.paused = false;
        }

        // The compositor's confirmation, not only our request
        function isLocked(): bool {
            return sessionLock.secure;
        }
    }
}
