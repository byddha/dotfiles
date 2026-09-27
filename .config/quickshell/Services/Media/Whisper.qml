pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Whisper - speech-to-text state for scripts/whisper
 *
 * listening: pw-record is capturing the microphone.
 * transcribing: recording stopped, the script is still running whisper-cli and pasting.
 * The script calls `qs ipc call whisper refresh` on each change, so the bar reacts at once;
 * the poll is only a fallback (fast while active, to catch the end).
 */
Singleton {
    id: root

    property bool listening: false
    property bool transcribing: false
    readonly property bool active: listening || transcribing

    function refresh() {
        statusProc.running = true;
    }

    Timer {
        interval: root.active ? 500 : 2000
        running: true
        repeat: true
        onTriggered: root.refresh()
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

    Component.onCompleted: refresh()
}
