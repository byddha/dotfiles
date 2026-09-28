import QtQuick
import Quickshell
import "../../Config"

/**
 * BarAnchoredPopup - A popup that opens past the bar's inner edge, next to its target, with room
 * around its content for a shadow.
 *
 * An xdg popup of the bar window: the compositor places it on the right output and slides it
 * back onto the screen near a corner. Takes no input.
 */
PopupWindow {
    id: root

    required property Item target
    property int shadowRoom: 24
    // From the target's inner-facing side to the content: the rest of the bar, then the popout gap
    readonly property real reach: (BarLayout.thickness - (BarLayout.vertical ? target.width : target.height)) / 2 + BarLayout.popoutGap - shadowRoom
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

    color: "transparent"
    mask: Region {}

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
}
