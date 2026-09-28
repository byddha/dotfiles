import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"

/**
 * BarWindow - The bar on one screen, along the edge BarLayout names.
 *
 * The window spans the whole edge and is thicker than the bar: it also holds the floating gap
 * and, on the inner side, room for the shadow. Only the bar and the gap between it and the
 * screen edge take input, so a pointer pushed against the edge still reaches the bar.
 */
PanelWindow {
    id: root

    required property ShellScreen modelData

    readonly property string edge: BarLayout.edge
    readonly property bool vertical: BarLayout.vertical
    // The bar sits against the window's far side on the bottom and right edges
    readonly property bool farEdge: edge === "bottom" || edge === "right"
    readonly property real crossPos: farEdge ? BarLayout.windowThickness - BarLayout.gap - BarLayout.thickness : BarLayout.gap
    // A fullscreen window is drawn over the bar; the bar also stops taking input and slides away
    readonly property bool coveredByFullscreen: Compositor.hasFullscreenOnScreen(modelData)

    screen: modelData
    color: "transparent"

    WlrLayershell.namespace: "bidshell:bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Normal
    exclusiveZone: BarLayout.reserved

    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }
    implicitWidth: vertical ? BarLayout.windowThickness : 0
    implicitHeight: vertical ? 0 : BarLayout.windowThickness

    mask: Region {
        item: root.coveredByFullscreen ? null : inputArea
    }

    Item {
        id: slide

        width: parent.width
        height: parent.height

        transform: Translate {
            readonly property real away: root.coveredByFullscreen ? BarLayout.windowThickness : 0

            x: root.edge === "left" ? -away : root.edge === "right" ? away : 0
            y: root.edge === "top" ? -away : root.edge === "bottom" ? away : 0

            Behavior on x {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        Item {
            id: inputArea

            x: root.vertical ? (root.farEdge ? bar.x : 0) : bar.x
            y: root.vertical ? bar.y : (root.farEdge ? bar.y : 0)
            width: root.vertical ? BarLayout.gap + BarLayout.thickness : bar.width
            height: root.vertical ? bar.height : BarLayout.gap + BarLayout.thickness
        }

        RectangularShadow {
            visible: BarLayout.floating
            anchors.fill: bar
            radius: bar.radius
            blur: BarLayout.shadowBlur
            offset: Qt.vector2d(0, BarLayout.shadowOffset)
            color: Qt.rgba(0, 0, 0, 0.45)
        }

        Rectangle {
            id: bar

            x: root.vertical ? root.crossPos : BarLayout.gap
            y: root.vertical ? BarLayout.gap : root.crossPos
            width: root.vertical ? BarLayout.thickness : parent.width - BarLayout.gap * 2
            height: root.vertical ? parent.height - BarLayout.gap * 2 : BarLayout.thickness
            radius: BarLayout.radius
            color: BarLayout.floating ? Theme.alpha(Theme.colLayer0, 0.96) : Theme.colLayer0
            border.width: BarLayout.floating ? 1 : 0
            border.color: Theme.outlineVariant

            Rectangle {
                visible: !BarLayout.floating
                x: root.edge === "left" ? parent.width - 1 : 0
                y: root.edge === "top" ? parent.height - 1 : 0
                width: root.vertical ? 1 : parent.width
                height: root.vertical ? parent.height : 1
                color: Theme.outlineVariant
            }
        }
    }
}
