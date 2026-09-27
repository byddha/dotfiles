pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Recording - Screen recording detection service
 *
 * Monitors the gpu-screen-recorder process to detect active screen recording.
 */
Singleton {
    id: root

    property bool recording: false

    // Poll status every 2 seconds
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: statusProc.running = true
    }

    Process {
        id: statusProc
        command: ["pgrep", "-f", "^gpu-screen-recorder"]
        onExited: (code, status) => {
            root.recording = (code === 0);
        }
    }

    Component.onCompleted: statusProc.running = true
}
