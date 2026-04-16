import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Utils"

Scope {
    id: root

    WlSessionLock {
        id: sessionLock
        locked: SessionLock.locked

        WlSessionLockSurface {
            id: surface
            color: "black"

            readonly property bool isPrimary: surface.screen?.model === Config.primaryMonitor

            LockContent {
                anchors.fill: parent
                visible: surface.isPrimary
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): string {
            Logger.info("IPC: lock.lock");
            SessionLock.lock();
            return "Locked";
        }

        function unlock(): string {
            Logger.info("IPC: lock.unlock");
            SessionLock.unlock();
            return "Unlocked";
        }

        function isLocked(): bool {
            return SessionLock.locked;
        }
    }
}
