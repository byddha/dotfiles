pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import "../../Config"
import "../../Services"

BarPopout {
    id: root

    // The first click on Shut down only arms it; a second one within 3 s shuts down
    property bool shutdownArmed: false

    WlrLayershell.namespace: "bidshell:power-menu"
    panelWidth: 232
    padding: 6

    onPanelClosed: shutdownArmed = false

    function run(action) {
        hidePanel();
        action();
    }

    function shutDown() {
        hidePanel();
        // A device that would be left with a low battery gets a reminder instead
        if (PeripheralBatteries.getLowBatteryDevices().length > 0)
            Settings.shutdownReminderVisible = true;
        else
            PowerActions.poweroff();
    }

    Timer {
        id: disarm

        interval: 3000
        running: root.shutdownArmed
        onTriggered: root.shutdownArmed = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 1

        MenuRow {
            icon: Lucide.lock
            label: "Lock"
            onActivated: root.run(PowerActions.lock)
        }
        MenuRow {
            icon: Lucide.moon
            label: "Suspend"
            onActivated: root.run(PowerActions.suspend)
        }
        MenuRow {
            icon: Lucide.logOut
            label: "Log out"
            onActivated: root.run(PowerActions.logout)
        }
        MenuRow {
            icon: Lucide.rotateCcw
            label: "Reboot"
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
            onActivated: {
                if (root.shutdownArmed)
                    root.shutDown();
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

    component MenuRow: Rectangle {
        id: row

        property string icon
        property string label
        property string keys: ""
        property bool danger: false
        // Shown as hovered, e.g. the armed Shut down
        property bool filled: false
        readonly property bool lit: area.containsMouse || filled

        signal activated

        Layout.fillWidth: true
        implicitHeight: 34
        radius: 6
        clip: true
        color: area.pressed ? (danger ? Qt.darker(Theme.accentRed, 1.15) : Theme.colLayer3) : lit ? (danger ? Theme.accentRed : Theme.colLayer2) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            BarIcon {
                text: row.icon
                color: row.danger ? (row.lit ? Theme.textColor : Theme.accentRed) : Theme.alpha(Theme.textSecondary, 0.66)
            }
            BarText {
                Layout.fillWidth: true
                text: row.label
                elide: Text.ElideRight
            }
            BarKeycap {
                visible: row.keys !== ""
                text: row.keys
            }
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            onClicked: row.activated()
        }
    }
}
