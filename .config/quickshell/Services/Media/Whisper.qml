pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

/**
 * Whisper - Speech-to-text recording detection service
 *
 * Monitors pw-record process with Whisper path to detect active transcription recording.
 */
Singleton {
    id: root

    property bool recording: false

    onRecordingChanged: Logger.info("Whisper:", recording ? "transcribing" : "idle")

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

    Component.onCompleted: {
        Logger.info("Whisper service initialized");
        statusProc.running = true;
    }
}
