pragma Singleton

import QtQuick
import Quickshell

/**
 * BarLayout - Where the bar is and how much room it takes, the one place that knows it.
 *
 * The bar window, the popouts that open from it and the panels that must stay clear of it
 * (sidebar, notifications, OSD) all read these values instead of repeating the arithmetic.
 */
Singleton {
    id: root

    readonly property string edge: {
        const position = Config.options.bar.position;
        return ["top", "bottom", "left", "right"].includes(position) ? position : "top";
    }
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property bool floating: Config.options.bar.floating

    readonly property int thickness: vertical ? 44 : 36
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
}
