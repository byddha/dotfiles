pragma Singleton

import QtQuick
import Quickshell
import "../Services"

/**
 * BarLayout - Where the bar is and how much room it takes, the one place that knows it.
 *
 * The bar window, the popouts that open from it and the panels that must stay clear of it
 * (sidebar, notifications, OSD) all read these values instead of repeating the arithmetic.
 */
Singleton {
    id: root

    readonly property string edge: {
        const position = Config.options.bar?.position;
        return ["top", "bottom", "left", "right"].includes(position) ? position : "top";
    }
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property bool floating: Config.options.bar?.floating === true

    readonly property int thickness: vertical ? 44 : 36
    // Hit area of a bar item across the bar
    readonly property int itemSize: vertical ? 32 : 28
    readonly property int gap: floating ? 8 : 0
    readonly property int radius: floating ? Theme.radiusWindow : 0

    readonly property int shadowOffset: 10
    readonly property int shadowBlur: 30
    // The window reaches this far past the bar on the inner side, so the shadow is not cut off
    readonly property int shadowRoom: floating ? shadowBlur + shadowOffset : 0

    // What the bar keeps free along its screen edge, for windows and other surfaces
    readonly property int reserved: gap + thickness
    readonly property int windowThickness: reserved + shadowRoom

    readonly property int popoutGap: Theme.spacingBase

    function reservedAt(side) {
        return side === edge ? reserved : 0;
    }

    // Exact because the bar window ignores other exclusive zones (BarExclusion reserves the space)
    function windowOrigin(screen) {
        return Qt.point(edge === "right" ? screen.width - windowThickness : 0, edge === "bottom" ? screen.height - windowThickness : 0);
    }

    // Top-left of a w x h popout opening from an item at rect (screen coordinates): past the bar's
    // inner edge, centered on the item along the bar, kept on the screen, on whole physical pixels
    function popoutPosition(screen, rect, w, h) {
        const scale = Compositor.monitorForScreen(screen)?.scale ?? 1;
        const snap = v => Math.round(v * scale) / scale;
        const margin = Math.max(gap, Theme.spacingBase);
        const along = (start, length, size, screenLength) => Math.max(margin, Math.min(screenLength - size - margin, start + length / 2 - size / 2));
        const away = reserved + popoutGap;

        switch (edge) {
        case "bottom":
            return Qt.point(snap(along(rect.x, rect.width, w, screen.width)), snap(screen.height - away - h));
        case "left":
            return Qt.point(snap(away), snap(along(rect.y, rect.height, h, screen.height)));
        case "right":
            return Qt.point(snap(screen.width - away - w), snap(along(rect.y, rect.height, h, screen.height)));
        default:
            return Qt.point(snap(along(rect.x, rect.width, w, screen.width)), snap(away));
        }
    }
}
