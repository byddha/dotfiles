pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../Config"
import "../../../Utils"
import "../../../Components"
import "../../CalendarPanel"

/**
 * CalendarPopup - Calendar popup window (follows TrayMenu pattern)
 *
 * Uses PopupWindow with anchor.item for correct positioning.
 * Signals for parent focus management.
 */
PopupWindow {
    id: calendarPopup

    // Anchor item must be set by parent
    property var anchorItem: null

    // Signals for parent focus management (same as TrayMenu)
    signal panelOpened(window: var)
    signal panelClosed

    implicitWidth: (contentLoader.item?.implicitWidth ?? 380) + Theme.spacingBase * 2
    implicitHeight: (contentLoader.item?.implicitHeight ?? 400) + Theme.spacingBase * 2
    visible: false
    color: "transparent"

    anchor.item: anchorItem
    anchor.rect.x: anchorItem ? (anchorItem.width / 2) - (implicitWidth / 2) : 0  // Center under anchor
    anchor.rect.y: anchorItem ? anchorItem.height : 0  // Below anchor (glued)

    // Emit panelClosed when visibility changes to false
    onVisibleChanged: {
        if (!visible) {
            panelClosed();
        }
    }

    function showPanel(item) {
        if (!item) {
            Logger.warn("anchorItem is undefined, won't show panel.");
            return;
        }
        anchorItem = item;
        visible = true;
        panelOpened(calendarPopup);  // Emit signal with window instance
        Qt.callLater(() => calendarPopup.anchor.updateAnchor());
        Logger.info("Panel opened");
    }

    function hidePanel() {
        visible = false;
        Logger.info("Panel hidden");
    }

    // Background with shadow
    Item {
        anchors.fill: parent

        Rectangle {
            id: panelBg
            anchors.fill: parent
            color: Theme.colLayer0
            radius: Theme.radiusBase
            border.color: Theme.colLayer0Border
            border.width: 1

            Loader {
                id: contentLoader
                anchors.fill: parent
                anchors.margins: Theme.spacingBase
                active: calendarPopup.visible

                sourceComponent: CalendarPanelContent {}
            }
        }
    }
}
