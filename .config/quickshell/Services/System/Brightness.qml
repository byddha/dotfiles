pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

Singleton {
    id: root

    // Properties
    property real brightness: 1.0  // 0.0 to 1.0
    property int maxBrightness: 100
    property int currentBrightness: 100
    property bool available: false

    Component.onCompleted: {
        checkAvailability();
    }

    // Check if brightnessctl is available
    function checkAvailability() {
        checkAvailabilityProcess.running = true;
    }

    // Update brightness from system
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

    // Set brightness (0.0 to 1.0)
    function setBrightness(value) {
        if (!root.available)
            return;
        const clampedValue = Math.max(0, Math.min(1, value));
        root.brightness = clampedValue;

        // Convert to absolute value
        const absoluteValue = Math.round(clampedValue * root.maxBrightness);
        root.currentBrightness = absoluteValue;

        setBrightnessProcess.command = ["brightnessctl", "set", absoluteValue.toString()];
        setBrightnessProcess.running = true;
    }

    // Set brightness by percentage (0-100)
    function setBrightnessPercent(percent) {
        setBrightness(percent / 100.0);
    }

    // Increase brightness by 5%
    function increase() {
        setBrightness(root.brightness + 0.05);
    }

    // Decrease brightness by 5%
    function decrease() {
        setBrightness(root.brightness - 0.05);
    }

    // Set to specific preset values
    function setToMax() {
        setBrightness(1.0);
    }

    function setToHalf() {
        setBrightness(0.5);
    }

    function setToMin() {
        setBrightness(0.05);  // Not 0 to avoid completely dark screen
    }

    // Process to check if brightnessctl is available
    Process {
        id: checkAvailabilityProcess
        command: ["which", "brightnessctl"]

        onExited: exitCode => {
            root.available = (exitCode === 0);
            if (root.available) {
                Logger.info("brightnessctl available, initializing...");
                updateBrightness();
            } else {
                Logger.warn("brightnessctl not found. Install with: sudo pacman -S brightnessctl");
            }
        }
    }

    // Process to get current brightness
    Process {
        id: getBrightnessProcess
        command: ["brightnessctl", "get"]

        stdout: StdioCollector {
            onStreamFinished: {
                const current = parseInt(text.trim());
                if (!isNaN(current)) {
                    root.currentBrightness = current;
                    updateMaxBrightness();
                    Logger.info(`Current: ${current}`);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    Logger.error(`Get brightness error: ${text}`);
                }
            }
        }
    }

    // Process to get max brightness
    Process {
        id: getMaxBrightnessProcess
        command: ["brightnessctl", "max"]

        stdout: StdioCollector {
            onStreamFinished: {
                const max = parseInt(text.trim());
                if (!isNaN(max) && max > 0) {
                    root.maxBrightness = max;
                    root.brightness = root.currentBrightness / root.maxBrightness;
                    Logger.info(`Max: ${max}, current: ${(root.brightness * 100).toFixed(0)}%`);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    Logger.error(`Get max brightness error: ${text}`);
                }
            }
        }
    }

    // Process to set brightness
    Process {
        id: setBrightnessProcess

        onExited: exitCode => {
            if (exitCode === 0) {
                Logger.info(`Set to ${(root.brightness * 100).toFixed(0)}%`);
            } else {
                Logger.error("Failed to set brightness");
                Qt.callLater(updateBrightness);
            }
        }
    }
}
