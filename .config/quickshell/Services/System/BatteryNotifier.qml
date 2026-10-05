import QtQuick
import Quickshell
import "../../Utils"
import ".."

// Low and critical battery notifications. Apart from Battery, so the lock and the greeter, which
// run as processes of their own and show the battery too, do not notify a second time.
Scope {
    Connections {
        target: Battery

        function onIsLowChanged() {
            if (!Battery.isLow)
                return;
            Quickshell.execDetached(["notify-send", "-e", "Low Battery", `Battery at ${Battery.percentage}%. Consider plugging in.`, "-u", "normal", "-a", "Battery"]);
            Logger.warn(`Low battery: ${Battery.percentage}%`);
        }

        function onIsCriticalChanged() {
            if (!Battery.isCritical)
                return;
            Quickshell.execDetached(["notify-send", "-e", "Critical Battery", `Battery at ${Battery.percentage}%! Plug in now!`, "-u", "critical", "-a", "Battery"]);
            Logger.error(`Critical battery: ${Battery.percentage}%`);
        }
    }
}
