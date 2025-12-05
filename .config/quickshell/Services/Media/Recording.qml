pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

/**
 * Recording - Screen recording detection service
 *
 * Monitors wf-recorder process to detect active screen recording.
 */
Singleton {
    id: root

    property bool recording: false

    onRecordingChanged: Logger.info("Recording:", recording ? "started" : "stopped")

    // Poll status every 2 seconds
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: statusProc.running = true
    }

    Process {
        id: statusProc
        command: ["pgrep", "wf-recorder"]
        onExited: (code, status) => {
            root.recording = (code === 0);
        }
    }

    Component.onCompleted: {
        Logger.info("Recording service initialized");
        statusProc.running = true;
    }
}
