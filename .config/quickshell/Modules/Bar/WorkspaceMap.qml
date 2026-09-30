pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components"

// The windows of one workspace where they really are, scaled down, with previews and app icons,
// next to the bar item that opened it; the one under the pointer is lit and named. A line joins
// where the drag started to the pointer. One layer over the whole screen, taking no input, so the
// line can run from the bar over the map: the workspace slot keeps the pointer while its button is
// down and tells this where it started and where it is, in the screen's coordinates.
PanelWindow {
    id: root

    required property int workspaceId
    // The item that opened it, in the screen's coordinates
    required property rect anchorRect
    required property point start
    required property point end
    // The end in the map's coordinates, and the window under it
    readonly property point mapPoint: map.mapFromItem(null, end.x, end.y)
    readonly property var hoveredWindow: windowAt(mapPoint)

    readonly property var monitor: Compositor.monitors.find(m => m.name === (screen?.name ?? "")) ?? null
    readonly property real screenWidth: (monitor?.width ?? 1) / (monitor?.scale ?? 1)
    readonly property real screenHeight: (monitor?.height ?? 1) / (monitor?.scale ?? 1)
    // Floating ones last, so they are drawn and found on top
    readonly property var windows: Compositor.shownWindows(workspaceId).sort((a, b) => a.floating - b.floating)
    // The screen and every window on the workspace (a scrolling layout reaches past the screen),
    // relative to the screen's top left
    readonly property rect bounds: {
        let left = 0, top = 0, right = screenWidth, bottom = screenHeight;
        for (const w of windows) {
            left = Math.min(left, w.at[0] - monitor.x);
            top = Math.min(top, w.at[1] - monitor.y);
            right = Math.max(right, w.at[0] - monitor.x + w.size[0]);
            bottom = Math.max(bottom, w.at[1] - monitor.y + w.size[1]);
        }
        return Qt.rect(left, top, right - left, bottom - top);
    }
    readonly property int mapHeight: 120
    readonly property real mapScale: Math.min(mapHeight / bounds.height, (monitor ? screenWidth * 0.6 : 1) / bounds.width)

    function containsPoint(point) {
        return point.x >= 0 && point.y >= 0 && point.x < map.width && point.y < map.height;
    }

    // Whether a point on the screen is over the map
    function onMap(screenPoint) {
        return containsPoint(map.mapFromItem(null, screenPoint.x, screenPoint.y));
    }

    // The topmost window under a point in the map's coordinates, or null
    function windowAt(point) {
        if (!containsPoint(point))
            return null;
        for (let i = windows.length - 1; i >= 0; i--) {
            const w = windows[i];
            const x = (w.at[0] - monitor.x - bounds.x) * mapScale;
            const y = (w.at[1] - monitor.y - bounds.y) * mapScale;
            if (point.x >= x && point.y >= y && point.x < x + w.size[0] * mapScale && point.y < y + w.size[1] * mapScale)
                return w;
        }
        return null;
    }

    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "bidshell:workspace-map"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        blur: 24
        offset: Qt.vector2d(0, 8)
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    Rectangle {
        id: card

        readonly property int padding: 10

        readonly property int margin: 8
        // Past the bar's inner edge, centred on the item and kept on the screen
        readonly property real along: BarLayout.vertical ? root.anchorRect.y + root.anchorRect.height / 2 - height / 2 : root.anchorRect.x + root.anchorRect.width / 2 - width / 2
        readonly property real inset: BarLayout.reserved + BarLayout.popoutGap

        x: {
            switch (BarLayout.edge) {
            case "left":
                return inset;
            case "right":
                return root.width - inset - width;
            default:
                return Math.max(margin, Math.min(root.width - margin - width, along));
            }
        }
        y: {
            switch (BarLayout.edge) {
            case "top":
                return inset;
            case "bottom":
                return root.height - inset - height;
            default:
                return Math.max(margin, Math.min(root.height - margin - height, along));
            }
        }
        // As wide as the map: a long title is elided, never widens the card
        implicitWidth: map.width + 2 * padding
        // One 16 px line with padding on both sides, which the app and title lines share
        implicitHeight: map.height + 16 + 3 * padding
        radius: 8
        color: Theme.chipSurface
        border.width: 1
        border.color: Theme.chipSurfaceNested

        Item {
            id: map

            x: (card.width - width) / 2
            y: card.padding
            width: Math.round(root.bounds.width * root.mapScale)
            height: Math.round(root.bounds.height * root.mapScale)

            // The screen, under the windows
            Rectangle {
                x: -root.bounds.x * root.mapScale
                y: -root.bounds.y * root.mapScale
                width: root.screenWidth * root.mapScale
                height: root.screenHeight * root.mapScale
                radius: Theme.radiusSmall
                color: Theme.hostSurface
            }

            Repeater {
                model: root.windows

                Rectangle {
                    id: tile

                    required property var modelData
                    readonly property bool lit: root.hoveredWindow?.address === modelData.address

                    // Whole-pixel edges, so the tiles of one column come out the same size
                    readonly property int x0: Math.round((modelData.at[0] - root.monitor.x - root.bounds.x) * root.mapScale)
                    readonly property int y0: Math.round((modelData.at[1] - root.monitor.y - root.bounds.y) * root.mapScale)
                    readonly property int x1: Math.round((modelData.at[0] + modelData.size[0] - root.monitor.x - root.bounds.x) * root.mapScale)
                    readonly property int y1: Math.round((modelData.at[1] + modelData.size[1] - root.monitor.y - root.bounds.y) * root.mapScale)

                    x: x0 + 1
                    y: y0 + 1
                    width: Math.max(2, x1 - x0 - 2)
                    height: Math.max(2, y1 - y0 - 2)
                    radius: Theme.radiusSmall
                    color: lit ? Theme.chipSurfaceNested : Theme.cardSurface
                    border.width: lit ? 2 : 1
                    border.color: lit ? Theme.primary : Theme.chipSurfaceNested

                    // One frame, taken as the map opens: it is up only while the button is held
                    ScreencopyView {
                        id: preview

                        anchors.fill: parent
                        anchors.margins: 1
                        captureSource: Compositor.toplevelFor(tile.modelData.address)
                        live: false
                        constraintSize: Qt.size(width, height)
                    }

                    // In a corner over the preview; centred and larger until there is one
                    BarAppIcon {
                        // Thin tiles (a stacked column) keep less margin, so their icons still fit;
                        // below 14 px an icon is only a dot
                        readonly property int margin: Math.min(tile.width, tile.height) < 36 ? 2 : 4
                        readonly property int fullSize: Math.floor(Math.min(32, tile.width - 2 * margin, tile.height - 2 * margin))

                        x: preview.hasContent ? tile.width - width - margin : (tile.width - width) / 2
                        y: preview.hasContent ? tile.height - height - margin : (tile.height - height) / 2
                        appClass: tile.modelData.class
                        size: preview.hasContent ? Math.min(20, fullSize) : fullSize
                        visible: size >= 14
                    }
                }
            }

            // What the screen shows of a workspace that reaches past it
            Rectangle {
                visible: root.bounds.width > root.screenWidth + 1 || root.bounds.height > root.screenHeight + 1
                x: -root.bounds.x * root.mapScale - 2
                y: -root.bounds.y * root.mapScale - 2
                width: root.screenWidth * root.mapScale + 4
                height: root.screenHeight * root.mapScale + 4
                radius: Theme.radiusBase
                color: "transparent"
                border.width: 1
                border.color: Theme.alpha(Theme.textColor, 0.6)
            }
        }

        // The app over the title, in the room one line with its padding took
        Column {
            x: card.padding
            y: map.y + map.height + 3
            width: card.width - 2 * card.padding

            StyledText {
                width: parent.width
                height: 14
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                role: "tertiary"
                font.pixelSize: Theme.fontSizeTiny
                text: root.hoveredWindow ? AppIcons.getDisplayName(root.hoveredWindow.class, root.hoveredWindow.title, root.hoveredWindow.xdgTag) : ""
            }
            StyledText {
                id: title

                width: parent.width
                height: 16
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                text: root.hoveredWindow?.title ?? ""
            }
        }
    }

    // Over the map, from where the drag started to the pointer
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Theme.alpha(Theme.primary, 0.6)
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: root.start.x
            startY: root.start.y

            PathLine {
                x: root.end.x
                y: root.end.y
            }
        }
    }

    Rectangle {
        x: root.start.x - width / 2
        y: root.start.y - height / 2
        width: 8
        height: 8
        radius: 4
        color: Theme.primary
    }

    Rectangle {
        x: root.end.x - width / 2
        y: root.end.y - height / 2
        width: 16
        height: 16
        radius: 8
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
    }
}
