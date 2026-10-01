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
        const range = Config.options.monitors?.[Compositor.monitorFor(barScreen)?.key ?? ""]?.workspaces;
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
            if (Compositor.workspaceApps(next.id).length > 0) {
                if (next.id !== activeId)
                    Compositor.switchWorkspace(next.id);
                return;
            }
        }
    }

    // The map of the hovered workspace, as a taskbar shows its thumbnails: it opens after a short
    // hover, follows the pointer to another workspace at once, and closes a moment after the pointer
    // has left both the workspaces and the map, so the way over to it never closes it
    property Item hoveredSlot: null
    property Item mapSlot: null
    // The last one shown: the map keeps it while it closes, so its bindings never see null
    property Item shownSlot: null
    onMapSlotChanged: if (mapSlot)
        shownSlot = mapSlot
    // After a click, until the pointer leaves that workspace
    property Item quietSlot: null

    // Crossing another workspace on the way to the open map must not swap it ("menu aim", as
    // macOS submenus): while the pointer heads into the triangle between where it was and the
    // map's near edge, the swap waits until it rests there or turns away. In this item's
    // coordinates: Wayland gives windows no screen position, so the map's edge is worked out from
    // where the popup opens (centred on its workspace, past the bar's inner edge).
    property Item aimSlot: null
    property point trailPoint
    property point pointerPoint
    readonly property point hoverPosition: pointerTracker.point.position

    onHoverPositionChanged: {
        const point = hoverPosition;
        // A few pixels of travel, so the heading is not just jitter
        if (Math.hypot(point.x - pointerPoint.x, point.y - pointerPoint.y) < 6)
            return;
        trailPoint = pointerPoint;
        pointerPoint = point;
        if (!aimSlot)
            return;
        if (aimingAtMap())
            aimTimer.restart();
        else
            swapTo(aimSlot);
    }

    function aimingAtMap() {
        const size = mapLoader.item?.cardSize;
        if (!size || !mapSlot)
            return false;
        const slot = mapSlot.mapToItem(root, 0, 0);
        const reach = (BarLayout.thickness - BarLayout.itemSize) / 2 + BarLayout.popoutGap;
        const edge = BarLayout.edge;
        // Near a screen end the compositor slides the popup back on: the bar window spans its
        // whole edge, so its coordinates along the bar are the screen's
        const offset = vertical ? mapToItem(null, 0, 0).y : mapToItem(null, 0, 0).x;
        const screenLength = vertical ? QsWindow.window.height : QsWindow.window.width;
        // The window slides with its shadow room, which is the same on both ends along the bar
        const pad = mapLoader.item.shadowRoom;
        const length = vertical ? size.height : size.width;
        const middle = vertical ? slot.y + mapSlot.height / 2 : slot.x + mapSlot.width / 2;
        const start = pad + Math.max(-offset, Math.min(screenLength - offset - length - 2 * pad, middle - length / 2 - pad));
        let a, b;
        if (vertical) {
            const x = edge === "left" ? slot.x + mapSlot.width + reach : slot.x - reach;
            a = Qt.point(x, start);
            b = Qt.point(x, start + length);
        } else {
            const y = edge === "top" ? slot.y + mapSlot.height + reach : slot.y - reach;
            a = Qt.point(start, y);
            b = Qt.point(start + length, y);
        }
        const side = (p, q, r) => (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x);
        const d1 = side(trailPoint, a, pointerPoint);
        const d2 = side(a, b, pointerPoint);
        const d3 = side(b, trailPoint, pointerPoint);
        return !((d1 < 0 || d2 < 0 || d3 < 0) && (d1 > 0 || d2 > 0 || d3 > 0));
    }

    function swapTo(slot) {
        aimTimer.stop();
        aimSlot = null;
        if (mapSlot && hoveredSlot === slot)
            mapSlot = slot;
    }

    function slotHovered(slot, hovered) {
        if (hovered) {
            hoveredSlot = slot;
            if (slot === quietSlot)
                return;
            if (!mapSlot) {
                showTimer.restart();
            } else if (slot !== mapSlot) {
                // The pointer's position comes after this, so its next move decides
                aimSlot = slot;
                aimTimer.restart();
            }
        } else if (hoveredSlot === slot) {
            hoveredSlot = null;
            if (quietSlot === slot)
                quietSlot = null;
            if (aimSlot === slot) {
                aimTimer.stop();
                aimSlot = null;
            }
        }
    }

    function closeMap() {
        showTimer.stop();
        quietSlot = hoveredSlot;
        mapSlot = null;
    }

    HoverHandler {
        id: pointerTracker
    }

    // Resting on the crossed workspace means it is the one wanted
    Timer {
        id: aimTimer

        interval: 150
        onTriggered: root.swapTo(root.aimSlot)
    }

    Timer {
        id: showTimer

        interval: 300
        onTriggered: {
            if (!root.hoveredSlot || !Compositor.hasWindowGeometry)
                return;
            Compositor.refreshWindows();
            root.mapSlot = root.hoveredSlot;
        }
    }

    Timer {
        interval: 300
        running: root.mapSlot !== null && root.hoveredSlot === null && !(mapLoader.item?.hovered ?? false)
        onTriggered: root.mapSlot = null
    }

    LazyLoader {
        id: mapLoader

        active: root.mapSlot !== null

        WorkspaceMap {
            target: root.shownSlot
            workspaceId: root.shownSlot?.modelData.id ?? 0
            workspaceTitle: root.shownSlot?.workspaceTitle ?? ""
            keys: root.shownSlot?.keys ?? ""
            detail: root.shownSlot?.detail ?? ""
            visible: true
            onTargetChanged: anchor.updateAnchor()
            onChosen: root.closeMap()
        }
    }

    Repeater {
        id: slots

        model: root.workspaces

        BarItem {
            id: slot

            required property var modelData
            readonly property var apps: Compositor.workspaceApps(modelData.id)
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
            readonly property string workspaceTitle: `Workspace ${modelData.label}`
            readonly property string keys: Compositor.keysFor(`Workspace ${modelData.id}`)
            readonly property string detail: apps.length === 0 ? "Empty" : apps.map(app => {
                const name = AppIcons.getDisplayName(app.appId, app.title, app.tag);
                return app.count > 1 ? `${name} ×${app.count}` : name;
            }).join(" · ")

            // The map shows the same, where there is one
            tooltipTitle: Compositor.hasWindowGeometry ? "" : workspaceTitle
            tooltipKeys: keys
            tooltipDetail: detail

            onHoveredChanged: root.slotHovered(slot, hovered)
            onClicked: mouse => {
                if (mouse.button !== Qt.LeftButton)
                    return;
                root.closeMap();
                if (!current)
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
                        appClass: app.modelData.appId
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
