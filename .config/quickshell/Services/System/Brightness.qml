pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

Singleton {
    id: root

    property alias brightness: device.brightness  // 0.0 to 1.0
    property alias maxBrightness: device.maxBrightness
    property alias currentBrightness: device.currentBrightness
    property bool available: false

    // Set brightness (0.0 to 1.0)
    function setBrightness(value) {
        device.set(value);
    }

    BrightnessCtl {
        id: device
        label: "screen"
        available: root.available
        brightness: 1.0
        maxBrightness: 100
        currentBrightness: 100
    }

    Process {
        running: true
        command: ["which", "brightnessctl"]

        onExited: exitCode => {
            root.available = (exitCode === 0);
            if (root.available) {
                device.update();
            } else {
                Logger.warn("brightnessctl not found. Install with: sudo pacman -S brightnessctl");
            }
        }
    }
}
