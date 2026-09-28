import QtQuick
import "../../Config"

/**
 * BarContent - The bar's sections: start (left or top), center and end (right or bottom).
 *
 * The clock sits exactly in the middle of the bar; what comes before and after it in the
 * center hugs it, so it never moves when media starts or a VPN connects.
 */
Item {
    id: root

    readonly property bool vertical: BarLayout.vertical
    readonly property int padding: 6
    // Between the clock and the center groups next to it
    readonly property int centerSpacing: 2

    // Position along the bar / across it, whole pixels
    function along(item, pos) {
        return vertical ? Qt.point(Math.round((width - item.width) / 2), Math.round(pos)) : Qt.point(Math.round(pos), Math.round((height - item.height) / 2));
    }

    Section {
        id: startSection

        readonly property point pos: root.along(this, root.padding)

        x: pos.x
        y: pos.y

        Workspaces {}
        BarDivider {
            visible: activeWindow.visible
        }
        ActiveWindowButton {
            id: activeWindow
        }
    }

    Section {
        id: beforeClock

        readonly property point pos: root.along(this, (root.vertical ? clock.y : clock.x) - root.centerSpacing - (root.vertical ? height : width))

        x: pos.x
        y: pos.y

        MediaButton {
            id: media
        }
        BarDivider {
            visible: media.visible
        }
    }

    ClockButton {
        id: clock

        readonly property point pos: root.along(this, ((root.vertical ? root.height : root.width) - (root.vertical ? height : width)) / 2)

        x: pos.x
        y: pos.y
    }

    Section {
        id: afterClock

        readonly property point pos: root.along(this, (root.vertical ? clock.y + clock.height : clock.x + clock.width) + root.centerSpacing)

        x: pos.x
        y: pos.y

        BarDivider {
            visible: whisper.visible || vpn.visible || recording.visible
        }
        WhisperButton {
            id: whisper
        }
        VpnButton {
            id: vpn
        }
        RecordingButton {
            id: recording
        }
    }

    Section {
        id: endSection

        readonly property point pos: root.along(this, (root.vertical ? root.height - height : root.width - width) - root.padding)

        x: pos.x
        y: pos.y

        Tray {
            id: tray
        }
        BarDivider {
            visible: tray.visibleChildren.length > 1
        }
        MicButton {}
        VolumeButton {}
        BarDivider {
            visible: batteries.visible || laptopBattery.visible
        }
        DeviceBatteriesButton {
            id: batteries
        }
        LaptopBatteryButton {
            id: laptopBattery
        }
        BarDivider {}
        NotificationsButton {}
        PowerButton {}
    }

    component Section: Grid {
        // One binding for the shape, so switching orientation never passes through a 1x1 grid
        columns: root.vertical ? 1 : Math.max(1, children.length)
        spacing: 2
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
    }
}
