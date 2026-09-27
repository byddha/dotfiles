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

    // Logical global area; gpu-screen-recorder records the native pixels of scaled monitors itself.
    // Even sizes: gsr widens odd ones by a pixel, which would reach past the area (and into the frame).
    function start(x: int, y: int, width: int, height: int) {
        const region = `${width - width % 2}x${height - height % 2}+${x}+${y}`;
        if (recording || starting)
            return;
        starting = true;
        Quickshell.execDetached(["bash", "-c", `mkdir -p ~/Videos/Screencasts && exec gpu-screen-recorder -w ${region} -f 30 -k h264 -o ~/Videos/Screencasts/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4`]);
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

    Process {
        id: statusProc
        command: ["pgrep", "-af", "^gpu-screen-recorder"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/-w (\d+)x(\d+)\+(-?\d+)\+(-?\d+)/);
                root.region = m ? Qt.rect(Number(m[3]), Number(m[4]), Number(m[1]), Number(m[2])) : Qt.rect(0, 0, 0, 0);
            }
        }
        onExited: code => {
            root.recording = code === 0;
            if (root.recording)
                root.starting = false;
            else
                root.stopping = false;
            if (!root.starting && !root.stopping)
                waitTimeout.stop();
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
