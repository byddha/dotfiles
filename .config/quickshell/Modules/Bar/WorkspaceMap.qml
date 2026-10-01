pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components"

// The windows of one workspace where they really are, scaled down, with previews and app icons.
// Under the pointer a window is lit and named, and a click goes to it; elsewhere on the map the
// workspace's own name, keys and apps show, and a click goes to the workspace. Workspaces opens and
// closes it on hover, as a taskbar does its thumbnails.
BarAnchoredPopup {
    id: root

    required property int workspaceId
    required property string workspaceTitle
    required property string keys
    required property string detail
    readonly property bool hovered: pointer.containsMouse
    readonly property var hoveredWindow: pointer.containsMouse ? windowAt(Qt.point(pointer.mouseX, pointer.mouseY)) : null

    readonly property var monitor: Compositor.monitors.find(m => m.name === (target?.QsWindow.window?.screen?.name ?? "")) ?? null
    readonly property real screenWidth: (monitor?.width ?? 1) / (monitor?.scale ?? 1)
    readonly property real screenHeight: (monitor?.height ?? 1) / (monitor?.scale ?? 1)
    // Floating ones last, so they are drawn and found on top
    readonly property var windows: monitor ? Compositor.windowsOn(workspaceId).sort((a, b) => a.floating - b.floating) : []
    // The screen and every window on the workspace (a scrolling layout reaches past the screen),
    // relative to the screen's top left
    readonly property rect bounds: {
        let left = 0, top = 0, right = screenWidth, bottom = screenHeight;
        for (const w of windows) {
            left = Math.min(left, w.x - monitor.x);
            top = Math.min(top, w.y - monitor.y);
            right = Math.max(right, w.x - monitor.x + w.width);
            bottom = Math.max(bottom, w.y - monitor.y + w.height);
        }
        return Qt.rect(left, top, right - left, bottom - top);
    }
    readonly property int mapHeight: 120
    readonly property real mapScale: Math.min(mapHeight / bounds.height, (monitor ? screenWidth * 0.6 : 1) / bounds.width)

    signal chosen

    // For the workspaces' aim check, which places it from the bar's side
    readonly property size cardSize: Qt.size(card.width, card.height)

    // The topmost window under a point in the map's coordinates, or null
    function windowAt(point) {
        for (let i = windows.length - 1; i >= 0; i--) {
            const w = windows[i];
            const x = (w.x - monitor.x - bounds.x) * mapScale;
            const y = (w.y - monitor.y - bounds.y) * mapScale;
            if (point.x >= x && point.y >= y && point.x < x + w.width * mapScale && point.y < y + w.height * mapScale)
                return w;
        }
        return null;
    }

    implicitWidth: card.implicitWidth + padLeft + padRight
    implicitHeight: card.implicitHeight + padTop + padBottom
    // Only the card: the shadow room around it must not hold the pointer
    mask: Region {
        item: card
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

        x: root.padLeft
        y: root.padTop
        // As wide as the map: a long title is elided, never widens the card
        implicitWidth: map.width + 2 * padding
        // One 16 px line with padding on both sides, which the two text lines share
        implicitHeight: map.height + 16 + 3 * padding
        radius: 8
        color: Theme.chipSurface
        border.width: 1
        border.color: Theme.chipSurfaceNested

        // Over the whole card, so the pointer stays "on the map" between tiles and over the text
        MouseArea {
            id: pointer

            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                const window = root.hoveredWindow;
                if (window)
                    Compositor.focusWindow(window.id);
                else
                    Compositor.switchWorkspace(root.workspaceId);
                root.chosen();
            }
        }

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
                    readonly property bool lit: root.hoveredWindow?.id === modelData.id

                    // Whole-pixel edges, so the tiles of one column come out the same size
                    readonly property int x0: Math.round((modelData.x - root.monitor.x - root.bounds.x) * root.mapScale)
                    readonly property int y0: Math.round((modelData.y - root.monitor.y - root.bounds.y) * root.mapScale)
                    readonly property int x1: Math.round((modelData.x + modelData.width - root.monitor.x - root.bounds.x) * root.mapScale)
                    readonly property int y1: Math.round((modelData.y + modelData.height - root.monitor.y - root.bounds.y) * root.mapScale)

                    x: x0 + 1
                    y: y0 + 1
                    width: Math.max(2, x1 - x0 - 2)
                    height: Math.max(2, y1 - y0 - 2)
                    radius: Theme.radiusSmall
                    color: lit ? Theme.chipSurfaceNested : Theme.cardSurface
                    border.width: lit ? 2 : 1
                    border.color: lit ? Theme.primary : Theme.chipSurfaceNested

                    // One frame, taken as the map opens
                    ScreencopyView {
                        id: preview

                        anchors.fill: parent
                        anchors.margins: 1
                        captureSource: Compositor.toplevelFor(tile.modelData.id)
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
                        appClass: tile.modelData.appId
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

        // The app over the window's title, or the workspace's apps over its name and keys; in the
        // room one line with its padding took
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
                text: root.hoveredWindow ? AppIcons.getDisplayName(root.hoveredWindow.appId, root.hoveredWindow.title, root.hoveredWindow.tag) : root.detail
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 16
                spacing: 6

                StyledText {
                    width: Math.min(implicitWidth, card.width - 2 * card.padding - (keycap.visible ? keycap.width + 6 : 0))
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeSmall
                    text: root.hoveredWindow?.title ?? root.workspaceTitle
                }
                Keycap {
                    id: keycap

                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.hoveredWindow && root.keys !== ""
                    text: root.keys
                }
            }
        }
    }
}
