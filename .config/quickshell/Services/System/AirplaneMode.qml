pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

/**
 * AirplaneMode - Airplane mode toggle service
 *
 * Uses nmcli to control all radios (no root required).
 */
Singleton {
    id: root

    property bool enabled: false

    // Poll status every 5 seconds
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.updateStatus()
    }

    // Check status using nmcli - airplane mode = all radios disabled
    Process {
        id: statusProc
        command: ["nmcli", "-t", "radio"]

        stdout: SplitParser {
            onRead: line => {
                // -t format: "WIFI-HW:enabled:WIFI:enabled:WWAN-HW:enabled:WWAN:enabled"
                // Airplane mode = wifi AND wwan both disabled
                const parts = line.split(":");
                // parts[2] = WIFI status, parts[6] = WWAN status (if exists)
                const wifiOff = parts[2] === "disabled";
                const wwanOff = parts.length > 6 ? parts[6] === "disabled" : true;
                root.enabled = wifiOff && wwanOff;
            }
        }
    }

    // Toggle processes
    Process {
        id: enableProc
        command: ["nmcli", "r", "all", "off"]
        onExited: root.updateStatus()
    }

    Process {
        id: disableProc
        command: ["nmcli", "r", "all", "on"]
        onExited: root.updateStatus()
    }

    function updateStatus() {
        statusProc.running = true;
    }

    function toggle() {
        if (enabled) {
            disableProc.running = true;
        } else {
            enableProc.running = true;
        }
    }

    Component.onCompleted: {
        Logger.info("Service initialized");
        updateStatus();
    }
}
