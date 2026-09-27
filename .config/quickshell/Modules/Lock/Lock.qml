import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Utils"

Scope {
    id: root

    // Lock-loss retry, as in DankMaterialShell: if the compositor drops or refuses the lock
    // while we still want it, toggle `locked` to request a new one.
    readonly property int maxLockRetries: 3
    property int lockRetryAttempts: 0
    property bool lockRetryPending: false

    WlSessionLock {
        id: sessionLock
        locked: SessionLock.locked && !root.lockRetryPending

        WlSessionLockSurface {
            id: surface
            color: "black"

            // Content on the primary monitor, or on the first screen when the primary is not
            // connected, so a password field always exists somewhere.
            readonly property bool isPrimary: {
                const screens = Quickshell.screens;
                const hasPrimary = screens.some(s => s.model === Config.primaryMonitor);
                return hasPrimary ? surface.screen?.model === Config.primaryMonitor : surface.screen === screens[0];
            }

            Loader {
                anchors.fill: parent
                active: surface.isPrimary
                sourceComponent: LockContent {}
            }
        }
    }

    Connections {
        target: sessionLock

        function onSecureChanged() {
            if (sessionLock.secure)
                root.lockRetryAttempts = 0;
        }

        function onLockedChanged() {
            if (sessionLock.locked || !SessionLock.locked || root.lockRetryPending)
                return;
            if (root.lockRetryAttempts >= root.maxLockRetries) {
                Logger.error("Compositor refused session lock", root.maxLockRetries, "times - resetting lock state");
                root.lockRetryAttempts = 0;
                SessionLock.unlock();
                return;
            }
            root.lockRetryAttempts++;
            root.lockRetryPending = true;
            lockRetryTimer.restart();
            Logger.warn("Session lock lost - retry", root.lockRetryAttempts, "/", root.maxLockRetries);
        }
    }

    Timer {
        id: lockRetryTimer
        interval: 1000
        onTriggered: root.lockRetryPending = false
    }

    IpcHandler {
        target: "lock"

        function lock(): string {
            SessionLock.lock();
            return "Locked";
        }

        function unlock(): string {
            SessionLock.unlock();
            return "Unlocked";
        }

        // `secure` is the compositor's confirmation, not just our request.
        function isLocked(): bool {
            return sessionLock.secure;
        }
    }
}
