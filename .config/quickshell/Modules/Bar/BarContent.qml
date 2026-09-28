import QtQuick
import "../../Config"

/**
 * BarContent - The bar's sections: start (left or top), center and end (right or bottom).
 *
 * The clock sits exactly in the middle of the bar; what comes before and after it in the
 * center hugs it, so it never moves when media starts or a VPN connects.
 *
 * When the content does not fit, the whole bar steps down a level (see BarItem.level): the
 * lowest level at which each half, start + center group + half the clock, fits in half the bar.
 * Every length comes from lengthAt(), which does not depend on the level shown, so choosing
 * one never feeds back into itself.
 */
Item {
    id: root

    readonly property bool vertical: BarLayout.vertical
    readonly property int padding: 6
    // Between the clock and the center groups next to it
    readonly property int centerSpacing: 2
    // Least room between a side section and the center groups
    readonly property int minGap: 12

    readonly property int level: {
        for (let level = 0; level < 3; level++) {
            if (fits(level))
                return level;
        }
        return 3;
    }

    function fits(level) {
        const half = (vertical ? height : width) / 2;
        const center = clock.lengthAt(level) / 2 + centerSpacing;
        const start = padding + startSection.lengthAt(level) + minGap + beforeClock.lengthAt(level) + center;
        const end = padding + endSection.lengthAt(level) + minGap + afterClock.lengthAt(level) + center;
        return start <= half && end <= half;
    }

    // Position along the bar / across it, whole pixels
    function along(item, pos) {
        return vertical ? Qt.point(Math.round((width - item.width) / 2), Math.round(pos)) : Qt.point(Math.round(pos), Math.round((height - item.height) / 2));
    }

    Section {
        id: startSection

        readonly property point pos: root.along(this, root.padding)

        x: pos.x
        y: pos.y

        Workspaces {
            level: root.level
        }
        BarDivider {
            visible: activeWindow.visible
        }
        ActiveWindowButton {
            id: activeWindow

            level: root.level
        }
    }

    Section {
        id: beforeClock

        readonly property point pos: root.along(this, (root.vertical ? clock.y : clock.x) - root.centerSpacing - (root.vertical ? height : width))

        x: pos.x
        y: pos.y

        MediaButton {
            id: media

            level: root.level
        }
        BarDivider {
            visible: media.visible
        }
    }

    ClockButton {
        id: clock

        readonly property point pos: root.along(this, ((root.vertical ? root.height : root.width) - (root.vertical ? height : width)) / 2)

        level: root.level
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

            level: root.level
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

            level: root.level
        }
        BarDivider {
            visible: tray.visible
        }
        MicButton {
            level: root.level
        }
        VolumeButton {
            level: root.level
        }
        BarDivider {
            visible: batteries.visible || laptopBattery.visible
        }
        DeviceBatteriesButton {
            id: batteries

            level: root.level
        }
        LaptopBatteryButton {
            id: laptopBattery

            level: root.level
        }
        BarDivider {}
        NotificationsButton {
            level: root.level
        }
        PowerButton {}
    }

    component Section: Grid {
        // One binding for the shape, so switching orientation never passes through a 1x1 grid
        columns: root.vertical ? 1 : Math.max(1, children.length)
        spacing: 2
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        // Visible children at that level, with the spacing between them
        function lengthAt(level) {
            let total = 0;
            let count = 0;
            for (const child of children) {
                if (!child.visible)
                    continue;
                total += child.lengthAt ? child.lengthAt(level) : (root.vertical ? child.implicitHeight : child.implicitWidth);
                count++;
            }
            return total + spacing * Math.max(0, count - 1);
        }
    }
}
