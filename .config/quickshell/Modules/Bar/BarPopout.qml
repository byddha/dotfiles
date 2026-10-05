import QtQuick
import Quickshell
import "../../Components"
import "../../Config"

/**
 * BarPopout - A Popout that opens from a bar item, placed by BarLayout.popoutPosition.
 *
 * The opener's place on the screen is taken when the popout opens; the position then follows
 * the panel's size.
 */
Popout {
    id: root

    property rect openerRect: Qt.rect(0, 0, 0, 0)
    readonly property point position: targetScreen ? BarLayout.popoutPosition(targetScreen, openerRect, panelSize.width, panelSize.height) : Qt.point(0, 0)

    panelBorderColor: Theme.outlineVariant
    shadowBlur: 40
    shadowOffset: 16
    shadowColor: Qt.rgba(0, 0, 0, 0.55)
    panelX: position.x
    panelY: position.y

    // The opener is in the bar window, or, with fromPopout, in another popout (whose window covers the screen)
    function openFrom(opener, fromPopout) {
        const barScreen = opener.QsWindow.window.screen;
        parentPopout = fromPopout ? opener.QsWindow.window : null;
        const origin = fromPopout ? Qt.point(0, 0) : BarLayout.windowOrigin(barScreen);
        const local = opener.mapToItem(null, 0, 0);
        openerRect = Qt.rect(origin.x + local.x, origin.y + local.y, opener.width, opener.height);
        targetScreen = barScreen;
        visible = true;
    }
}
