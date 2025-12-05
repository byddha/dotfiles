pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Utils"

/**
 * Idle inhibitor service
 *
 * Prevents the system from going idle (screen dimming, suspend, etc.)
 */
Singleton {
    id: root

    property bool inhibit: false

    function toggleInhibit() {
        inhibit = !inhibit;
        Logger.info(`Idle inhibitor ${inhibit ? "enabled" : "disabled"}`);
    }

    IdleInhibitor {
        id: idleInhibitor
        enabled: root.inhibit
        window: PanelWindow {
            // Inhibitor requires a "visible" surface, but we make it invisible
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            anchors {
                right: true
                bottom: true
            }
            // Make it not interactable
            mask: Region {
                item: null
            }
        }
    }
}
