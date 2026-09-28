pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../Config"
import "../../Services"
import "../../Components"

/**
 * Workspaces - One slot per workspace this screen shows, with the apps open on it.
 *
 * Hyprland: the range set for the monitor in config (monitors.<model>.workspaces).
 * Niri: the workspaces of this output. The wheel steps through the occupied ones.
 */
Grid {
    id: root

    readonly property bool vertical: BarLayout.vertical
    readonly property var barScreen: QsWindow.window?.screen ?? null
    readonly property int activeId: Compositor.activeWorkspaceIdForScreen(barScreen)
    readonly property var workspaces: {
        if (Compositor.isNiri)
            return Compositor.workspaces.filter(ws => ws.output === barScreen?.name).sort((a, b) => (a.idx ?? 0) - (b.idx ?? 0)).map(ws => ({
                        id: ws.id,
                        label: ws.idx ?? ws.id
                    }));
        const range = Config.options.monitors?.[barScreen?.model ?? ""]?.workspaces;
        if (!range)
            return [];
        const list = [];
        for (let id = range[0]; id <= range[1]; id++)
            list.push({
                id: id,
                label: id
            });
        return list;
    }

    // One binding for the shape, so switching orientation never passes through a 1x1 grid
    columns: vertical ? 1 : Math.max(1, children.length)
    spacing: 2

    // Set by BarContent. At level 3 a horizontal slot shows only its first app, with "+n" for the rest.
    property int level: 0

    function lengthAt(level) {
        let total = 0;
        for (let i = 0; i < slots.count; i++)
            total += slots.itemAt(i)?.lengthAt(level) ?? 0;
        return total + spacing * Math.max(0, slots.count - 1);
    }

    // Wheel up: the next occupied workspace, wrapping around; down: the previous one
    function step(wheel) {
        const direction = wheel.angleDelta.y > 0 ? 1 : wheel.angleDelta.y < 0 ? -1 : 0;
        const count = workspaces.length;
        if (direction === 0 || count === 0)
            return;
        const start = Math.max(0, workspaces.findIndex(ws => ws.id === activeId));
        for (let i = 1; i <= count; i++) {
            const next = workspaces[(((start + direction * i) % count) + count) % count];
            if (Compositor.getWorkspaceApps(next.id).length > 0) {
                if (next.id !== activeId)
                    Compositor.switchWorkspace(next.id);
                return;
            }
        }
    }

    Repeater {
        id: slots

        model: root.workspaces

        BarItem {
            id: slot

            required property var modelData
            readonly property var apps: Compositor.getWorkspaceApps(modelData.id)
            readonly property bool current: modelData.id === root.activeId

            readonly property bool firstAppOnly: !root.vertical && root.level >= 3

            level: root.level
            marked: current
            spacing: BarLayout.appIconGap

            function lengthAt(level) {
                if (root.vertical)
                    return implicitHeight;
                const shown = level >= 3 ? Math.min(1, apps.length) : apps.length;
                return padded(label.implicitWidth + shown * (BarLayout.appIconSize + spacing));
            }
            tooltipTitle: `Workspace ${modelData.label}`
            tooltipKeys: Compositor.keysFor(`Workspace ${modelData.id}`)
            tooltipDetail: apps.length === 0 ? "Empty" : apps.map(app => {
                const name = AppIcons.getDisplayName(app.class, app.title, app.xdgTag);
                return app.count > 1 ? `${name} ×${app.count}` : name;
            }).join(" · ")

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && !current)
                    Compositor.switchWorkspace(modelData.id);
            }
            onWheel: wheel => root.step(wheel)

            StyledText {
                id: label

                font.pixelSize: BarLayout.workspaceNumberSize
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                color: slot.current ? Theme.primary : Theme.alpha(Theme.textSecondary, slot.apps.length === 0 ? 0.4 : BarLayout.workspaceNumberOpacity)
                text: slot.modelData.label
            }

            Repeater {
                model: slot.apps

                Item {
                    id: app

                    required property var modelData
                    required property int index
                    // The first app stands for the whole workspace when only it is shown
                    readonly property string badge: slot.firstAppOnly && slot.apps.length > 1 ? `+${slot.apps.length - 1}` : modelData.count > 1 ? String(modelData.count) : ""

                    visible: !slot.firstAppOnly || index === 0
                    implicitWidth: BarLayout.appIconSize
                    implicitHeight: BarLayout.appIconSize

                    BarAppIcon {
                        anchors.fill: parent
                        appClass: app.modelData.class
                    }

                    // Window count, on the corner away from the active marker; the border is a ring in the
                    // item's color around the pill
                    Rectangle {
                        readonly property int ring: 2

                        visible: app.badge !== ""
                        x: root.vertical && BarLayout.edge === "left" ? -7 - ring : parent.width - width + 7 + ring
                        y: BarLayout.edge === "bottom" ? parent.height - height + 6 + ring : -6 - ring
                        width: Math.max(height, count.implicitWidth + 8 + ring * 2)
                        height: BarLayout.badgeSize + ring * 2
                        radius: height / 2
                        color: Theme.colLayer3
                        border.width: ring
                        border.color: slot.hovered || slot.marked ? Theme.colLayer2 : Theme.colLayer0

                        StyledText {
                            id: count

                            anchors.centerIn: parent
                            font.pixelSize: BarLayout.badgeTextSize
                            font.weight: Font.Bold
                            text: app.badge
                        }
                    }
                }
            }
        }
    }
}
