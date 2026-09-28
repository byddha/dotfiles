pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

/**
 * Recording - screen recording with gpu-screen-recorder
 *
 * The recorder runs detached so a recording survives shell reloads; its state comes from pgrep.
 * starting / stopping cover the gap between a request and the process really starting or
 * finishing its file, and poll fast so the bar follows within a quarter second.
 */
Singleton {
    id: root

    property bool recording: false
    property bool starting: false
    property bool stopping: false
    // Recorded area in global logical coordinates, read from the recorder's command line
    // (so it survives shell reloads); width 0 when unknown
    property rect region: Qt.rect(0, 0, 0, 0)
    // When the running recorder started (ms since epoch), from its process age; 0 when not recording
    property double startedAt: 0
    // Sound the running recorder captures, from its command line
    property bool hasAudio: false
    property bool hasMic: false

    // Logical global area; gpu-screen-recorder records the native pixels of scaled monitors itself.
    // Even sizes: gsr widens odd ones by a pixel, which would reach past the area (and into the frame).
    function start(x: int, y: int, width: int, height: int, audio: bool, mic: bool) {
        const region = `${width - width % 2}x${height - height % 2}+${x}+${y}`;
        // One mixed track: system audio and / or the microphone
        const sources = [audio ? "default_output" : "", mic ? "default_input" : ""].filter(s => s).join("|");
        const audioArgs = sources ? `-a '${sources}' -ac aac ` : "";
        if (recording || starting)
            return;
        starting = true;
        Quickshell.execDetached(["bash", "-c", `mkdir -p ~/Videos/Screencasts && exec gpu-screen-recorder -w ${region} ${audioArgs}-f 30 -k h264 -o ~/Videos/Screencasts/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4`]);
        waitTimeout.restart();
    }

    // SIGINT lets gpu-screen-recorder finalize the file
    function stop() {
        if (!recording || stopping)
            return;
        stopping = true;
        Quickshell.execDetached(["pkill", "-INT", "-f", "^gpu-screen-recorder"]);
        waitTimeout.restart();
    }

    Timer {
        interval: root.starting || root.stopping ? 250 : 2000
        running: true
        repeat: true
        onTriggered: statusProc.running = true
    }

    // One line per recorder: "<seconds running> <command line>". The ^ anchors keep bash itself out.
    Process {
        id: statusProc
        command: ["bash", "-c", "for p in $(pgrep -f '^gpu-screen-recorder'); do echo \"$(ps -o etimes= -p $p) $(tr '\\0' ' ' < /proc/$p/cmdline)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n")[0] ?? "";
                root.recording = line !== "";
                const m = line.match(/-w (\d+)x(\d+)\+(-?\d+)\+(-?\d+)/);
                root.region = m ? Qt.rect(Number(m[3]), Number(m[4]), Number(m[1]), Number(m[2])) : Qt.rect(0, 0, 0, 0);
                root.hasAudio = line.includes("default_output");
                root.hasMic = line.includes("default_input");
                // Only move the start time on a real change, so the shown timer does not jitter
                const started = root.recording ? Date.now() - parseInt(line) * 1000 : 0;
                if (Math.abs(started - root.startedAt) > 1500)
                    root.startedAt = started;
                if (root.recording)
                    root.starting = false;
                else
                    root.stopping = false;
                if (!root.starting && !root.stopping)
                    waitTimeout.stop();
            }
        }
    }

    Timer {
        id: waitTimeout
        interval: 10000
        onTriggered: {
            if (root.starting)
                Logger.warn("gpu-screen-recorder did not start");
            if (root.stopping)
                Logger.warn("gpu-screen-recorder did not stop after SIGINT");
            root.starting = false;
            root.stopping = false;
        }
    }

    Component.onCompleted: statusProc.running = true
}
