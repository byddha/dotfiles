pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../Config"
import "../../../Utils"
import "../../../Components"
import "../../../Services"
import "../../CalendarPanel"

/**
 * CalendarPopup - Calendar popup window (follows TrayMenu pattern)
 *
 * Uses a full-screen transparent PanelWindow so Niri can receive outside clicks.
 * Signals for parent focus management.
 */
PanelWindow {
    id: calendarPopup

    // Anchor item must be set by parent
    property var anchorItem: null
    property var targetScreen: null
    property real popupX: 0
    property real popupY: 0

    // Signals for parent focus management (same as TrayMenu)
    signal panelOpened(window: var)
    signal panelClosed

    screen: targetScreen
    implicitWidth: 0
    implicitHeight: 0
    visible: false
    color: "transparent"

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.namespace: "bidshell:calendar-popup"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? (Compositor.useHyprlandFocusGrab ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    // Emit panelClosed when visibility changes to false
    onVisibleChanged: {
        if (!visible) {
            panelClosed();
        } else {
            Qt.callLater(updatePosition);
        }
    }

    function updatePosition() {
        if (!anchorItem || !targetScreen)
            return;
        const pos = anchorItem.mapToGlobal(0, 0);
        const screenX = targetScreen.x || 0;
        const screenY = targetScreen.y || 0;
        const w = panelBg.implicitWidth;
        const h = panelBg.implicitHeight;
        popupX = Math.max(8, Math.min((targetScreen.width || width) - w - 8, pos.x - screenX + (anchorItem.width / 2) - (w / 2)));
        popupY = Math.max(8, Math.min((targetScreen.height || height) - h - 8, pos.y - screenY + anchorItem.height));
    }

    function showPanel(item, panelScreen) {
        if (!item) {
            Logger.warn("anchorItem is undefined, won't show panel.");
            return;
        }
        anchorItem = item;
        targetScreen = panelScreen ?? item.QsWindow?.window?.screen ?? null;
        visible = true;
        panelOpened(calendarPopup);  // Emit signal with window instance
        Qt.callLater(updatePosition);
        Logger.info("Panel opened");
    }

    function hidePanel() {
        visible = false;
        Logger.info("Panel hidden");
    }

    MouseArea {
        anchors.fill: parent
        enabled: calendarPopup.visible
        onClicked: calendarPopup.hidePanel()
    }

    Item {
        focus: calendarPopup.visible
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                calendarPopup.hidePanel();
                event.accepted = true;
            }
        }
    }

    // Background with shadow
    Item {
        x: calendarPopup.popupX
        y: calendarPopup.popupY
        width: panelBg.implicitWidth
        height: panelBg.implicitHeight

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: mouse => {
                mouse.accepted = true;
            }
            onClicked: mouse => {
                mouse.accepted = true;
            }
        }

        Rectangle {
            id: panelBg
            width: (contentLoader.item?.implicitWidth ?? 380) + Theme.spacingBase * 2
            height: (contentLoader.item?.implicitHeight ?? 400) + Theme.spacingBase * 2
            implicitWidth: width
            implicitHeight: height
            color: Theme.colLayer0
            radius: Theme.radiusBase
            border.color: Theme.colLayer0Border
            border.width: 1

            onImplicitWidthChanged: Qt.callLater(calendarPopup.updatePosition)
            onImplicitHeightChanged: Qt.callLater(calendarPopup.updatePosition)

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
