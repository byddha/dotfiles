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

            // Held or dragged, the map of the workspace opens; letting go on a window there goes to it,
            // on the rest of the map or back on this slot to the workspace (the click below), anywhere
            // else nowhere. Only where the compositor gives window positions.
            property point pressPoint
            property point pointer
            property bool mapOpen: false

            // A point in the item's coordinates on the screen: the bar window spans its whole edge
            function screenPoint(point) {
                const window = QsWindow.window;
                const inWindow = mapToItem(null, point.x, point.y);
                return Qt.point(inWindow.x + (BarLayout.edge === "right" ? window.screen.width - window.width : 0), inWindow.y + (BarLayout.edge === "bottom" ? window.screen.height - window.height : 0));
            }

            function openMap() {
                if (mapOpen || !Compositor.hasWindowGeometry)
                    return;
                Compositor.refreshWindows();
                mapOpen = true;
            }

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && !current)
                    Compositor.switchWorkspace(modelData.id);
            }
            onLeftPressed: position => {
                pressPoint = position;
                pointer = position;
                hold.restart();
            }
            onLeftMoved: position => {
                pointer = position;
                // Past a small drag, so a click with a shaky hand stays a click
                if (Math.hypot(position.x - pressPoint.x, position.y - pressPoint.y) > 6)
                    openMap();
            }
            onLeftReleased: position => {
                hold.stop();
                pointer = position;
                if (map.item?.onMap(screenPoint(position))) {
                    const window = map.item.hoveredWindow;
                    if (window)
                        Compositor.focusWindow(window.address);
                    else if (!current)
                        Compositor.switchWorkspace(modelData.id);
                }
                mapOpen = false;
            }
            onWheel: wheel => root.step(wheel)

            Timer {
                id: hold

                interval: 250
                onTriggered: slot.openMap()
            }

            LazyLoader {
                id: map

                active: slot.mapOpen

                WorkspaceMap {
                    screen: slot.QsWindow.window?.screen ?? null
                    workspaceId: slot.modelData.id
                    anchorRect: {
                        const topLeft = slot.screenPoint(Qt.point(0, 0));
                        return Qt.rect(topLeft.x, topLeft.y, slot.width, slot.height);
                    }
                    start: slot.screenPoint(slot.pressPoint)
                    end: slot.screenPoint(slot.pointer)
                    visible: true
                }
            }

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
                        color: Theme.chipSurfaceNested
                        border.width: ring
                        border.color: slot.hovered || slot.marked ? Theme.chipSurface : Theme.hostSurface

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
