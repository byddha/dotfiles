pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

Singleton {
    id: root

    // Properties
    property real brightness: 0.0  // 0.0 to 1.0
    property int maxBrightness: 1
    property int currentBrightness: 0
    property bool available: false
    property string deviceName: ""
    property real stepSize: 1.0  // For slider snapping (1/maxBrightness)

    Component.onCompleted: {
        Logger.info("KeyboardBrightness service starting, available:", root.available);
        detectDevice();
    }

    onAvailableChanged: {
        Logger.info("KeyboardBrightness.available changed to:", root.available);
    }

    // Poll for external changes (sysfs doesn't support inotify)
    Timer {
        id: pollTimer
        interval: 1000
        running: root.available
        repeat: true
        onTriggered: root.pollBrightness()
    }

    // Detect keyboard backlight device
    function detectDevice() {
        detectDeviceProcess.running = true;
    }

    // Poll brightness without triggering max update
    function pollBrightness() {
        if (!root.available)
            return;
        pollBrightnessProcess.running = true;
    }

    // Update brightness from system (full init)
    function updateBrightness() {
        if (!root.available)
            return;
        getBrightnessProcess.running = true;
    }

    // Update max brightness from system
    function updateMaxBrightness() {
        if (!root.available)
            return;
        getMaxBrightnessProcess.running = true;
    }

    // Set brightness (0.0 to 1.0) - snaps to discrete levels
    function setBrightness(value) {
        if (!root.available)
            return;
        const clampedValue = Math.max(0, Math.min(1, value));

        // Snap to nearest discrete level
        const absoluteValue = Math.round(clampedValue * root.maxBrightness);
        const snappedValue = absoluteValue / root.maxBrightness;

        root.brightness = snappedValue;
        root.currentBrightness = absoluteValue;

        setBrightnessProcess.command = ["brightnessctl", "-d", root.deviceName, "set", absoluteValue.toString()];
        setBrightnessProcess.running = true;
    }

    // Toggle keyboard backlight on/off
    function toggle() {
        if (root.brightness > 0) {
            setBrightness(0);
        } else {
            setBrightness(1);
        }
    }

    // Cycle through brightness levels (useful for discrete levels like 0, 1, 2)
    function cycle() {
        const nextLevel = (root.currentBrightness + 1) % (root.maxBrightness + 1);
        setBrightness(nextLevel / root.maxBrightness);
    }

    // Process to detect keyboard backlight device
    Process {
        id: detectDeviceProcess
        command: ["brightnessctl", "--class=leds", "-l"]

        property bool foundDevice: false

        stdout: StdioCollector {
            onStreamFinished: {
                // Look for kbd_backlight in output
                const lines = text.split('\n');
                for (const line of lines) {
                    const match = line.match(/Device '([^']*kbd_backlight[^']*)'/);
                    if (match) {
                        root.deviceName = match[1];
                        detectDeviceProcess.foundDevice = true;
                        Logger.info(`Keyboard backlight found: ${root.deviceName}`);
                        return;
                    }
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && detectDeviceProcess.foundDevice) {
                root.available = true;
                updateBrightness();
            } else {
                root.available = false;
                if (exitCode !== 0) {
                    Logger.warn("brightnessctl not available or failed");
                } else {
                    Logger.info("No keyboard backlight device found");
                }
            }
        }
    }

    // Process to poll current brightness (lightweight, no chain)
    Process {
        id: pollBrightnessProcess
        command: ["brightnessctl", "-d", root.deviceName, "get"]

        stdout: StdioCollector {
            onStreamFinished: {
                const current = parseInt(text.trim());
                if (!isNaN(current) && current !== root.currentBrightness) {
                    root.currentBrightness = current;
                    root.brightness = current / root.maxBrightness;
                }
            }
        }
    }

    // Process to get current brightness (initial load)
    Process {
        id: getBrightnessProcess
        command: ["brightnessctl", "-d", root.deviceName, "get"]

        stdout: StdioCollector {
            onStreamFinished: {
                const current = parseInt(text.trim());
                if (!isNaN(current)) {
                    root.currentBrightness = current;
                    updateMaxBrightness();
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    Logger.error(`Get kbd brightness error: ${text}`);
                }
            }
        }
    }

    // Process to get max brightness
    Process {
        id: getMaxBrightnessProcess
        command: ["brightnessctl", "-d", root.deviceName, "max"]

        stdout: StdioCollector {
            onStreamFinished: {
                const max = parseInt(text.trim());
                if (!isNaN(max) && max > 0) {
                    root.maxBrightness = max;
                    root.stepSize = 1.0 / max;
                    root.brightness = root.currentBrightness / root.maxBrightness;
                    Logger.info(`Kbd max: ${max}, stepSize: ${root.stepSize}, current: ${(root.brightness * 100).toFixed(0)}%`);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    Logger.error(`Get kbd max brightness error: ${text}`);
                }
            }
        }
    }

    // Process to set brightness
    Process {
        id: setBrightnessProcess

        onExited: exitCode => {
            if (exitCode === 0) {
                Logger.info(`Kbd brightness set to ${root.currentBrightness}/${root.maxBrightness}`);
            } else {
                Logger.error("Failed to set keyboard brightness");
                Qt.callLater(updateBrightness);
            }
        }
    }
}
