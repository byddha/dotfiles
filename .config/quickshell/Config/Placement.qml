pragma Singleton

import QtQuick
import Quickshell

/**
 * Placement - Where the surfaces that float over windows go (notifications, sidebar, OSD),
 * from the config, checked against the allowed values.
 *
 * They ignore exclusive zones and keep clear of the bar themselves, on every side they touch:
 * a sidebar on the same side as a vertical bar opens right next to it.
 */
Singleton {
    // A section the config file has replaces the adapter's defaults, so any key may be missing
    readonly property string notificationsPosition: Config.options.notifications?.position ?? ""
    readonly property string notificationsVertical: notificationsPosition.startsWith("top") ? "top" : "bottom"
    readonly property string notificationsHorizontal: {
        const side = notificationsPosition.split("-")[1];
        return ["left", "center", "right"].includes(side) ? side : "right";
    }
    readonly property string sidebarSide: Config.options.sidebar?.side === "left" ? "left" : "right"
    readonly property string osdSide: Config.options.osd?.position === "left" ? "left" : "right"

    // Distance from a screen edge that keeps a surface `gap` away from the bar, or from the edge
    function inset(side, gap) {
        return BarLayout.reservedAt(side) + gap;
    }
}
