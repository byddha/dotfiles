import QtQuick
import QtQuick.Layouts
import "../Config"
import "../Services"

// The power actions, for the bar's power menu and for the lock and the greeter
ColumnLayout {
    id: root

    // "session" (the bar), "lock" (no Lock) or "greeter" (no Lock, no Log out)
    property string context: "session"
    // The keybind shown on a row, by its name; none on the lock and the greeter, where they do not work
    property var keysFor: name => ""
    // The bar first reminds about peripherals with a low battery
    property var shutDown: PowerActions.poweroff
    // The first click on Shut down only arms it; a second one within 3 s shuts down
    property bool shutdownArmed: false

    // An action was chosen: the menu closes
    signal chosen

    function run(action) {
        chosen();
        action();
    }

    spacing: 1

    Timer {
        id: disarm

        interval: 3000
        running: root.shutdownArmed
        onTriggered: root.shutdownArmed = false
    }

    MenuRow {
        visible: root.context === "session"
        icon: Lucide.lock
        label: "Lock"
        keys: root.keysFor("Lock")
        onActivated: root.run(PowerActions.lock)
    }
    MenuRow {
        icon: Lucide.moon
        label: "Suspend"
        keys: root.keysFor("Suspend")
        onActivated: root.run(PowerActions.suspend)
    }
    MenuRow {
        visible: root.context !== "greeter"
        icon: Lucide.logOut
        label: "Log out"
        keys: root.keysFor("Log out")
        onActivated: root.run(PowerActions.logout)
    }
    MenuRow {
        icon: Lucide.rotateCcw
        label: "Reboot"
        keys: root.keysFor("Reboot")
        onActivated: root.run(PowerActions.reboot)
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Theme.outlineVariant
    }

    MenuRow {
        id: shutdownRow

        danger: true
        filled: root.shutdownArmed
        icon: Lucide.power
        label: root.shutdownArmed ? "Click again to shut down" : "Shut down"
        keys: root.keysFor("Shut down")
        onActivated: {
            if (root.shutdownArmed)
                root.run(root.shutDown);
            else
                root.shutdownArmed = true;
        }

        // Time left to confirm
        Rectangle {
            visible: root.shutdownArmed
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            height: 2
            color: Theme.alpha(Theme.textColor, 0.8)

            NumberAnimation on width {
                running: root.shutdownArmed
                from: shutdownRow.width
                to: 0
                duration: disarm.interval
            }
        }
    }
}
