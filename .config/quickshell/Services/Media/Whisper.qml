pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Whisper - Speech-to-text recording detection service
 *
 * Monitors pw-record process with Whisper path to detect active transcription recording.
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
        command: ["pgrep", "-f", "pw-record.*Whisper"]
        onExited: (code, status) => {
            root.recording = (code === 0);
        }
    }

    Component.onCompleted: statusProc.running = true
}
