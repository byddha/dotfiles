import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Utils"

Item { // Window
    id: root
    property var toplevel
    property var windowData
    property var monitorData
    property var scale
    property var availableWorkspaceWidth
    property var availableWorkspaceHeight
    property bool restrictToWorkspace: true
    property real initX: Math.max(((windowData?.at[0] ?? 0) - (monitorData?.x ?? 0) - (monitorData?.reserved?.[0] ?? 0)) * root.scale, 0) + xOffset
    property real initY: Math.max(((windowData?.at[1] ?? 0) - (monitorData?.y ?? 0) - (monitorData?.reserved?.[1] ?? 0)) * root.scale, 0) + yOffset
    property real xOffset: 0
    property real yOffset: 0
    property int widgetMonitorId: 0

    property var targetWindowWidth: (windowData?.size[0] ?? 100) * scale
    property var targetWindowHeight: (windowData?.size[1] ?? 100) * scale

    property var iconToWindowRatio: 0.25
    property var xwaylandIndicatorToIconRatio: 0.35
    property var iconToWindowRatioCompact: 0.45
    property var entry: DesktopEntries.heuristicLookup(windowData?.class)
    property var iconPath: Quickshell.iconPath(entry?.icon ?? windowData?.class ?? "application-x-executable", "image-missing")
    property bool compactMode: Theme.fontSizeTiny * 4 > targetWindowHeight || Theme.fontSizeTiny * 4 > targetWindowWidth

    property bool indicateXWayland: windowData?.xwayland ?? false

    x: initX
    y: initY
    width: Math.min((windowData?.size[0] ?? 100) * root.scale, availableWorkspaceWidth)
    height: Math.min((windowData?.size[1] ?? 100) * root.scale, availableWorkspaceHeight)
    opacity: 1

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: Theme.roundingWindow * root.scale
        }
    }

    Behavior on x {
        animation: Theme.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on y {
        animation: Theme.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on width {
        animation: Theme.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on height {
        animation: Theme.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    ScreencopyView {
        id: windowPreview
        anchors.fill: parent
        captureSource: Settings.overviewVisible ? root.toplevel : null
        live: true

        // Apply 180° rotation if monitor is configured for it
        transform: Rotation {
            origin.x: windowPreview.width / 2
            origin.y: windowPreview.height / 2
            angle: {
                const wsId = windowData?.workspace?.id ?? 1;
                const monitors = Config.options?.monitors ?? {};
                // Find which monitor owns this workspace
                for (const [monName, monConfig] of Object.entries(monitors)) {
                    const range = monConfig?.workspaces;
                    if (range && wsId >= range[0] && wsId <= range[1]) {
                        return monConfig?.forceRotate ? 180 : 0;
                    }
                }
                return 0;
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.roundingWindow * root.scale
            color: ColorUtils.transparentize(Theme.colLayer2)
            border.color : ColorUtils.transparentize(ThemeService.base03, 0.7)
            border.width : 1
        }

        ColumnLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Theme.fontSizeTiny * 0.5

            Image {
                id: windowIcon
                property var iconSize: {
                    return Math.min(targetWindowWidth, targetWindowHeight) * (root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio) / (root.monitorData?.scale ?? 1);
                }
                Layout.alignment: Qt.AlignHCenter
                source: root.iconPath
                width: iconSize
                height: iconSize
                sourceSize: Qt.size(iconSize, iconSize)

                Behavior on width {
                    animation: Theme.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on height {
                    animation: Theme.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
            }
        }
    }
}
