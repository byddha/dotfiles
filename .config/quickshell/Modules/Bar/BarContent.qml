import QtQuick
import "../../Config"

/**
 * BarContent - The bar's sections: start (left or top), center and end (right or bottom).
 *
 * The workspaces sit exactly in the middle of the bar; the active window before them hugs
 * them, so they never move when the window title changes.
 *
 * When the content does not fit, the whole bar steps down a level (see BarItem.level): the
 * lowest level at which each half, start + center group + half the workspaces, fits in half the bar.
 * Every length comes from lengthAt(), which does not depend on the level shown, so choosing
 * one never feeds back into itself.
 */
Item {
    id: root

    readonly property bool vertical: BarLayout.vertical
    readonly property int padding: 6
    // Between the workspaces and the active window next to them
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
        const center = workspaces.lengthAt(level) / 2 + centerSpacing;
        const start = padding + startSection.lengthAt(level) + minGap + beforeWorkspaces.lengthAt(level) + center;
        const end = padding + endSection.lengthAt(level) + minGap + center;
        return start <= half && end <= half;
    }

    // The workspaces' start along the bar: exactly in the middle while the center group fits on
    // both sides of them; when even level 3 does not fit, the whole center block in the middle of the room
    // the side sections leave, so it never covers them. From the lengths the level is chosen by,
    // not the shown sizes: an item that grows on hover (media) must not move the workspaces.
    readonly property real workspacesStart: {
        const length = vertical ? height : width;
        const size = item => item.lengthAt(level);
        const ideal = (length - size(workspaces)) / 2;
        const lowest = padding + size(startSection) + minGap + size(beforeWorkspaces) + centerSpacing;
        const highest = length - padding - size(endSection) - minGap - centerSpacing - size(workspaces);
        if (lowest <= highest)
            return Math.max(lowest, Math.min(highest, ideal));
        return (lowest + highest) / 2;
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

        ClockButton {
            level: root.level
        }
        BarDivider {
            visible: media.visible
        }
        MediaButton {
            id: media

            level: root.level
        }
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
        id: beforeWorkspaces

        readonly property point pos: root.along(this, (root.vertical ? workspaces.y : workspaces.x) - root.centerSpacing - (root.vertical ? height : width))

        x: pos.x
        y: pos.y

        ActiveWindowButton {
            id: activeWindow

            level: root.level
        }
        BarDivider {
            visible: activeWindow.visible
        }
    }

    Workspaces {
        id: workspaces

        readonly property point pos: root.along(this, root.workspacesStart)

        level: root.level
        x: pos.x
        y: pos.y
    }

    Section {
        id: endSection

        readonly property point pos: root.along(this, (root.vertical ? root.height - height : root.width - width) - root.padding)

        x: pos.x
        y: pos.y

        PlasmaApplets {
            id: plasmaApplets

            level: root.level
        }
        Tray {
            id: tray

            level: root.level
        }
        BarDivider {
            visible: tray.visible || plasmaApplets.visible
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
