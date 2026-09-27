pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../Utils"
import "../../../Services"

/**
 * BarPopup - Base for popups opened from bar buttons.
 *
 * A full-screen transparent PanelWindow so Niri can receive outside clicks.
 * The owner drives focus via panelOpened/panelClosed; children form the panel,
 * which is placed at (offsetX, offsetY) from the anchor item and clamped to the screen.
 */
PanelWindow {
    id: root

    property var anchorItem: null
    property var targetScreen: null
    property real popupX: 0
    property real popupY: 0
    property real offsetX: anchorItem ? (anchorItem.width / 2) - (panel.width / 2) : 0
    property real offsetY: anchorItem ? anchorItem.height : 0
    default property alias content: panel.data

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

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? (Compositor.useHyprlandFocusGrab ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

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
        const w = panel.width;
        const h = panel.height;
        popupX = Math.max(8, Math.min((targetScreen.width || width) - w - 8, pos.x - screenX + offsetX));
        popupY = Math.max(8, Math.min((targetScreen.height || height) - h - 8, pos.y - screenY + offsetY));
    }

    function showPanel(item, panelScreen) {
        if (!item) {
            Logger.warn("anchorItem is undefined, won't show panel.");
            return;
        }
        anchorItem = item;
        targetScreen = panelScreen ?? item.QsWindow?.window?.screen ?? null;
        visible = true;
        panelOpened(root);
        Qt.callLater(updatePosition);
    }

    function hidePanel() {
        visible = false;
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.visible
        onClicked: root.hidePanel()
    }

    Item {
        focus: root.visible
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.hidePanel();
                event.accepted = true;
            }
        }
    }

    // Swallows clicks on the panel so they don't reach the close-on-click area.
    MouseArea {
        x: panel.x
        y: panel.y
        width: panel.width
        height: panel.height
        acceptedButtons: Qt.AllButtons
        onPressed: mouse => {
            mouse.accepted = true;
        }
        onClicked: mouse => {
            mouse.accepted = true;
        }
    }

    Item {
        id: panel
        x: root.popupX
        y: root.popupY
        width: childrenRect.width
        height: childrenRect.height
    }
}
