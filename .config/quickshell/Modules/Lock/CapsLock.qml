import QtQuick
import Quickshell
import Quickshell.Io

// Caps Lock, from the keyboards' LEDs: the compositor sets them, any user can read them (so the
// greeter too), and they are right before the first key. Polled, as sysfs does not report the change.
Item {
    id: root

    property bool on: false

    Process {
        running: true
        command: ["sh", "-c", "printf '%s\\n' /sys/class/leds/*::capslock/brightness"]
        stdout: StdioCollector {
            onStreamFinished: leds.model = text.split("\n").filter(path => path !== "" && !path.includes("*"))
        }
    }

    Variants {
        id: leds

        FileView {
            required property string modelData

            path: modelData
            blockAllReads: true
        }
    }

    Timer {
        running: leds.instances.length > 0
        interval: 300
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let on = false;
            for (const led of leds.instances) {
                led.reload();
                on = on || led.text().trim() !== "0";
            }
            root.on = on;
        }
    }
}
