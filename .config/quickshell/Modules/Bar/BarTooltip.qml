import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "../../Config"

/**
 * BarTooltip - A card that opens past the bar's inner edge, next to its target.
 *
 * An xdg popup of the bar window: the compositor places it on the right output and slides it
 * back onto the screen near a corner. Takes no input.
 */
PopupWindow {
    id: root

    required property Item target
    property bool shown: false
    property string title: ""
    property string keys: ""
    property string detail: ""

    // Room around the card for its shadow
    readonly property int shadowRoom: 24
    // From the target's inner-facing side to the card: the rest of the bar, then the popout gap
    readonly property real reach: (BarLayout.thickness - (BarLayout.vertical ? target.width : target.height)) / 2 + BarLayout.popoutGap - shadowRoom

    visible: shown && title !== "" && delay.done
    color: "transparent"
    mask: Region {}
    implicitWidth: card.implicitWidth + shadowRoom * 2
    implicitHeight: card.implicitHeight + shadowRoom * 2

    anchor.item: target
    anchor.rect: {
        const w = target.width;
        const h = target.height;
        switch (BarLayout.edge) {
        case "bottom":
            return Qt.rect(0, -reach, w, h + reach);
        case "left":
            return Qt.rect(0, 0, w + reach, h);
        case "right":
            return Qt.rect(-reach, 0, w + reach, h);
        default:
            return Qt.rect(0, 0, w, h + reach);
        }
    }
    anchor.edges: awayFromBar
    anchor.gravity: awayFromBar

    readonly property int awayFromBar: {
        switch (BarLayout.edge) {
        case "bottom":
            return Edges.Top;
        case "left":
            return Edges.Right;
        case "right":
            return Edges.Left;
        default:
            return Edges.Bottom;
        }
    }

    Timer {
        id: delay

        property bool done: false

        interval: 400
        running: root.shown
        onRunningChanged: if (running)
            done = false
        onTriggered: done = true
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

        x: root.shadowRoom
        y: root.shadowRoom
        implicitWidth: lines.implicitWidth + 20
        implicitHeight: lines.implicitHeight + 16
        radius: 8
        color: Theme.colLayer2
        border.width: 1
        border.color: Theme.colLayer3

        ColumnLayout {
            id: lines

            x: 10
            y: 8
            spacing: 2

            RowLayout {
                spacing: 8

                BarText {
                    text: root.title
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                BarKeycap {
                    visible: root.keys !== ""
                    text: root.keys
                }
            }

            BarText {
                visible: root.detail !== ""
                role: "secondary"
                text: root.detail
                font.pixelSize: 12
                lineHeight: 1.35
            }
        }
    }
}
