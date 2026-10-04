import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

// One brightnessctl device, shared by the Brightness and KeyboardBrightness singletons
Scope {
    id: root

    required property string label
    property bool available: false
    property var deviceArgs: []
    // Report the brightness the device actually lands on instead of the requested value
    property bool snapToLevels: false

    property real brightness: 0
    property int maxBrightness: 1
    property int currentBrightness: 0

    // Reads current then max brightness
    function update() {
        if (root.available)
            getProcess.running = true;
    }

    // Picks up external changes without re-reading max
    function poll() {
        if (root.available)
            pollProcess.running = true;
    }

    // Applies a brightness read from outside, without re-reading max
    function sync(current) {
        if (!isNaN(current) && current !== root.currentBrightness) {
            root.currentBrightness = current;
            root.brightness = current / root.maxBrightness;
        }
    }

    function set(value) {
        if (!root.available)
            return;
        const clampedValue = Math.max(0, Math.min(1, value));
        const absoluteValue = Math.round(clampedValue * root.maxBrightness);
        root.brightness = root.snapToLevels ? absoluteValue / root.maxBrightness : clampedValue;
        root.currentBrightness = absoluteValue;

        setProcess.command = ["brightnessctl", ...root.deviceArgs, "set", absoluteValue.toString()];
        setProcess.running = true;
    }

    Process {
        id: pollProcess
        command: ["brightnessctl", ...root.deviceArgs, "get"]

        stdout: StdioCollector {
            onStreamFinished: root.sync(parseInt(text.trim()))
        }
    }

    Process {
        id: getProcess
        command: ["brightnessctl", ...root.deviceArgs, "get"]

        stdout: StdioCollector {
            onStreamFinished: {
                const current = parseInt(text.trim());
                if (!isNaN(current)) {
                    root.currentBrightness = current;
                    if (root.available)
                        getMaxProcess.running = true;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    Logger.error(`Get ${root.label} brightness error: ${text}`);
                }
            }
        }
    }

    Process {
        id: getMaxProcess
        command: ["brightnessctl", ...root.deviceArgs, "max"]

        stdout: StdioCollector {
            onStreamFinished: {
                const max = parseInt(text.trim());
                if (!isNaN(max) && max > 0) {
                    root.maxBrightness = max;
                    root.brightness = root.currentBrightness / root.maxBrightness;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    Logger.error(`Get ${root.label} max brightness error: ${text}`);
                }
            }
        }
    }

    Process {
        id: setProcess

        onExited: exitCode => {
            if (exitCode !== 0) {
                Logger.error(`Failed to set ${root.label} brightness`);
                Qt.callLater(root.update);
            }
        }
    }
}
