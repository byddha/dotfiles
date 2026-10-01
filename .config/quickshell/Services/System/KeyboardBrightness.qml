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
    property real stepSize: 1.0 / device.maxBrightness  // For slider snapping

    // Set brightness (0.0 to 1.0) - snaps to discrete levels
    function setBrightness(value) {
        device.set(value);
    }

    function toggle() {
        setBrightness(root.brightness > 0 ? 0 : 1);
    }

    // Cycle through brightness levels (useful for discrete levels like 0, 1, 2)
    function cycle() {
        const nextLevel = (root.currentBrightness + 1) % (root.maxBrightness + 1);
        setBrightness(nextLevel / root.maxBrightness);
    }

    BrightnessCtl {
        id: device
        label: "keyboard"
        available: root.available
        deviceArgs: ["-d", root.deviceName]
        snapToLevels: true
    }

    // Poll for external changes (sysfs doesn't support inotify)
    Timer {
        interval: 1000
        running: root.available
        repeat: true
        onTriggered: device.poll()
    }

    Process {
        id: detectDeviceProcess
        running: true
        command: ["brightnessctl", "--class=leds", "-l"]

        property bool foundDevice: false

        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split('\n')) {
                    const match = line.match(/Device '([^']*kbd_backlight[^']*)'/);
                    if (match) {
                        root.deviceName = match[1];
                        detectDeviceProcess.foundDevice = true;
                        return;
                    }
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.available = exitCode === 0 && detectDeviceProcess.foundDevice;
            if (root.available)
                device.update();
            else if (exitCode !== 0)
                Logger.warn("brightnessctl not available or failed");
        }
    }
}
