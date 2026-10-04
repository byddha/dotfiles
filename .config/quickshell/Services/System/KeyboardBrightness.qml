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

    function readBrightnessFile() {
        brightnessFile.reload();
        device.sync(parseInt(brightnessFile.text().trim()));
    }

    FileView {
        id: brightnessFile
        path: root.deviceName ? `/sys/class/leds/${root.deviceName}/brightness` : ""
        blockAllReads: true
    }

    // Software writes (brightnessctl, upower) modify brightness itself
    FileView {
        path: brightnessFile.path
        preload: false
        watchChanges: root.available
        onFileChanged: Qt.callLater(root.readBrightnessFile)
    }

    // Firmware changes (Fn key) only notify brightness_hw_changed, which errors on read until the first one
    FileView {
        path: root.deviceName ? `/sys/class/leds/${root.deviceName}/brightness_hw_changed` : ""
        preload: false
        printErrors: false
        watchChanges: root.available
        onFileChanged: Qt.callLater(root.readBrightnessFile)
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
