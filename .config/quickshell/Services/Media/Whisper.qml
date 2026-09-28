pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Whisper - speech-to-text state for scripts/whisper
 *
 * listening: pw-record is capturing the microphone.
 * transcribing: recording stopped, the script is still running whisper-cli and pasting.
 * The script calls `qs ipc call whisper refresh` on each change, so the bar reacts at once. The
 * state is also read at startup, to pick up a run that began before a shell restart, and polled
 * while active only, in case the script dies before its last call.
 */
Singleton {
    id: root

    property bool listening: false
    property bool transcribing: false
    readonly property bool active: listening || transcribing
    // When the current listening started (ms since epoch), 0 when not listening
    property double listeningSince: 0

    onListeningChanged: listeningSince = listening ? Date.now() : 0

    function refresh() {
        statusProc.running = true;
        // The script calls right after starting pw-record, which may not be up yet
        followUp.restart();
    }

    Timer {
        id: followUp

        interval: 2000
    }

    Timer {
        interval: 1000
        running: root.active || followUp.running
        repeat: true
        onTriggered: statusProc.running = true
    }

    // [p] / [w]: keeps the patterns from matching this bash command line itself
    Process {
        id: statusProc
        command: ["bash", "-c", "if pgrep -f '[p]w-record.*Whisper' >/dev/null; then echo listening; elif pgrep -f 'scripts/[w]hisper' >/dev/null; then echo transcribing; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim();
                root.listening = state === "listening";
                root.transcribing = state === "transcribing";
            }
        }
    }

    Component.onCompleted: statusProc.running = true
}
