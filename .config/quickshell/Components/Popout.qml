pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Config"
import "../Utils"
import "../Services"

/**
 * Popout - Base for every panel that opens over the desktop (bar popups, sidebar).
 *
 * A full-screen transparent layer window, so outside clicks (also on Niri) close it; Esc closes it too.
 * The panel sits next to anchorItem (bar popups) or at panelX / panelY when there is no anchor.
 * It holds exactly one content child, which fills it: the panel takes that child's implicit size
 * (height clamped to maxPanelHeight), and the child gets the real size back. Sizes only flow one way.
 * As DankMaterialShell's DankPopoutHost (_contentWarm / _surfaceFrameReady): contentWarm stays true after
 * the first open, so kept-loaded content is never rebuilt, and `presented` turns true only after the
 * window drew its first frame, so an open animation never shows content that is still laying out.
 */
PanelWindow {
    id: root

    property Item anchorItem: null
    property var targetScreen: null
    property real offsetX: anchorItem ? (anchorItem.width / 2) - (panel.width / 2) : 0
    property real offsetY: anchorItem ? anchorItem.height : 0
    property real panelX: 0
    property real panelY: 0
    // A width <= 0 follows the content
    property real panelWidth: 0
    property real maxPanelHeight: Infinity
    property int padding: 0
    property color panelColor: Theme.colLayer0
    property color panelBorderColor: Theme.popupBorder
    // Values from DankMaterialShell's elevationLevel2 (Common/Theme.qml)
    property real shadowBlur: 8
    property real shadowOffset: 4
    property color shadowColor: Qt.rgba(0, 0, 0, 0.25)
    property bool slideFromRight: false
    // false: the owner closes it (e.g. binds visible) when dismissed() fires
    property bool closeOnDismiss: true
    property bool useFocusGrab: false

    property bool contentWarm: false
    property bool presented: false
    default property alias content: contentHolder.data
    readonly property size panelSize: Qt.size(panel.width, panel.height)
    readonly property Item contentItem: contentHolder.children[0] ?? null

    signal panelOpened(window: var)
    signal panelClosed
    signal dismissed

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
        presented = false;
        wrapper.escapePressed = false;
        if (visible) {
            contentWarm = true;
            Qt.callLater(updatePosition);
            // The grab must be switched on after the window is mapped, never bound to visible
            Qt.callLater(() => focusGrab.active = root.useFocusGrab && Compositor.useHyprlandFocusGrab);
        } else {
            focusGrab.active = false;
            panelClosed();
        }
    }

    function updatePosition() {
        if (!anchorItem || !targetScreen) {
            popupX = panelX;
            popupY = panelY;
            return;
        }
        const pos = anchorItem.mapToGlobal(0, 0);
        const screenX = targetScreen.x || 0;
        const screenY = targetScreen.y || 0;
        popupX = Math.max(8, Math.min((targetScreen.width || width) - panel.width - 8, pos.x - screenX + offsetX));
        popupY = Math.max(8, Math.min((targetScreen.height || height) - panel.height - 8, pos.y - screenY + offsetY));
    }

    property real popupX: panelX
    property real popupY: panelY

    function showPanel(item, panelScreen) {
        if (!item) {
            Logger.warn("anchorItem is undefined, won't show panel.");
            return;
        }
        anchorItem = item;
        targetScreen = panelScreen ?? item.QsWindow?.window?.screen ?? null;
        // Place the panel before it is shown, so the first frame is already in the right place
        updatePosition();
        visible = true;
        panelOpened(root);
        Qt.callLater(updatePosition);
    }

    function hidePanel() {
        visible = false;
    }

    function dismiss() {
        dismissed();
        if (closeOnDismiss)
            hidePanel();
    }

    FocusGrab {
        id: focusGrab
        windows: [root]
        active: false
        onCleared: root.dismiss()
    }

    Connections {
        target: wrapper.Window.window
        enabled: root.visible && !root.presented

        function onFrameSwapped() {
            root.presented = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.visible
        onClicked: root.dismiss()
    }

    Item {
        id: wrapper
        // Ancestor of all content, so Esc from a focused field inside (that did not use it) still closes.
        // Closes on release: closing on press unmaps the window with Esc still held, keyboard focus goes back
        // to the app below together with the held key, and that app gets the Esc too (a video leaves fullscreen).
        focus: root.visible
        property bool escapePressed: false
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                escapePressed = true;
                event.accepted = true;
            }
        }
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Escape && escapePressed && !event.isAutoRepeat) {
                escapePressed = false;
                event.accepted = true;
                root.dismiss();
            }
        }
        x: root.popupX
        y: root.popupY
        width: panel.width
        height: panel.height
        opacity: !root.slideFromRight || root.presented ? 1 : 0

        Behavior on opacity {
            enabled: root.slideFromRight
            NumberAnimation {
                duration: Theme.animation.elementMoveFast.duration
                easing.type: Theme.animation.elementMoveFast.type
                easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
            }
        }

        transform: Translate {
            x: !root.slideFromRight || root.presented ? 0 : wrapper.width + 10

            Behavior on x {
                enabled: root.slideFromRight
                NumberAnimation {
                    duration: Theme.animation.elementMoveEnter.duration
                    easing.type: Theme.animation.elementMoveEnter.type
                    easing.bezierCurve: Theme.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        // Swallows clicks on the panel so they don't reach the close-on-click area
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: mouse => mouse.accepted = true
        }

        RectangularShadow {
            anchors.fill: panel
            radius: Theme.radiusWindow
            blur: root.shadowBlur
            offset: Qt.vector2d(0, root.shadowOffset)
            color: root.shadowColor
        }

        Rectangle {
            id: panel
            width: root.panelWidth > 0 ? root.panelWidth : (root.contentItem?.implicitWidth ?? 0) + root.padding * 2
            height: Math.min(root.maxPanelHeight, (root.contentItem?.implicitHeight ?? 0) + root.padding * 2)
            color: root.panelColor
            radius: Theme.radiusWindow
            border.width: 1
            border.color: root.panelBorderColor

            onWidthChanged: Qt.callLater(root.updatePosition)
            onHeightChanged: Qt.callLater(root.updatePosition)

            Item {
                id: contentHolder
                anchors.fill: parent
                anchors.margins: root.padding
            }
        }
    }
}
