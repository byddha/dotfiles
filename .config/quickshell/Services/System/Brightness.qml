pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../../Utils"

Singleton {
    id: root

    property alias brightness: device.brightness  // 0.0 to 1.0
    property alias maxBrightness: device.maxBrightness
    property alias currentBrightness: device.currentBrightness
    property bool available: false
    property string deviceName: ""

    // Set brightness (0.0 to 1.0)
    function setBrightness(value) {
        device.set(value);
    }

    function readBrightnessFile() {
        brightnessFile.reload();
        device.sync(parseInt(brightnessFile.text().trim()));
    }

    BrightnessCtl {
        id: device
        label: "screen"
        available: root.available
        deviceArgs: ["-d", root.deviceName]
        brightness: 1.0
        maxBrightness: 100
        currentBrightness: 100
    }

    // "name,class,current,percent,max" per device
    Process {
        id: detectDeviceProcess
        running: true
        command: ["brightnessctl", "-m", "--class=backlight"]

        property string foundDevice: ""

        stdout: StdioCollector {
            onStreamFinished: detectDeviceProcess.foundDevice = text.trim().split("\n")[0].split(",")[0]
        }

        onExited: exitCode => {
            root.deviceName = exitCode === 0 ? detectDeviceProcess.foundDevice : "";
            root.available = root.deviceName !== "";
            if (root.available)
                device.update();
            else
                Logger.warn("No backlight device found. Install brightnessctl with: sudo pacman -S brightnessctl");
        }
    }

    // Read on each udev change instead of spawning brightnessctl
    FileView {
        id: brightnessFile
        path: root.deviceName ? `/sys/class/backlight/${root.deviceName}/brightness` : ""
        blockAllReads: true
    }

    // External changes (brightness keys, other tools) arrive as kernel uevents
    Process {
        id: udevMonitor
        running: true
        // setpriv: the kernel ends it with qs, also when qs dies without cleaning up (SIGTERM, crash)
        command: ["setpriv", "--pdeathsig", "TERM", "--", "udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]

        property int failures: 0

        stdout: SplitParser {
            onRead: line => {
                // The first event can arrive with a leading newline
                const match = line.trim().match(/^KERNEL\[[\d.]+\]\s+(\w+)\s+(\S+)\s+\(backlight\)$/);
                if (!match)
                    return;
                udevMonitor.failures = 0;
                const action = match[1];
                const name = match[2].split("/").pop();
                if (action === "change" && name === root.deviceName)
                    Qt.callLater(root.readBrightnessFile);
                else if (action === "add" || action === "remove")
                    detectDeviceProcess.running = true;
            }
        }

        onExited: exitCode => {
            if (udevMonitor.failures >= 5) {
                Logger.error(`udevadm monitor exited (${exitCode}), giving up on external brightness changes`);
                return;
            }
            udevMonitorRestart.interval = 2000 * Math.pow(2, udevMonitor.failures);
            udevMonitor.failures++;
            Logger.warn(`udevadm monitor exited (${exitCode}), restarting in ${udevMonitorRestart.interval / 1000}s`);
            udevMonitorRestart.start();
        }
    }

    Timer {
        id: udevMonitorRestart
        onTriggered: udevMonitor.running = true
    }
}
