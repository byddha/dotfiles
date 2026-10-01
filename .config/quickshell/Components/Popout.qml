pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Config"
import "../Services"

/**
 * Popout - Base for every panel that opens over the desktop (bar popups, sidebar).
 *
 * A full-screen transparent layer window, so outside clicks (also on Niri) close it; Esc closes it too.
 * The panel sits at panelX / panelY, bound so it moves in the same frame its size changes.
 * It holds exactly one content child, which fills it: the panel takes that child's implicit size
 * (height clamped to maxPanelHeight), and the child gets the real size back. Sizes only flow one way.
 * As DankMaterialShell's DankPopoutHost (_contentWarm / _surfaceFrameReady): contentWarm stays true after
 * the first open, so kept-loaded content is never rebuilt, and `presented` turns true only after the
 * window drew its first frame, so an open animation never shows content that is still laying out.
 */
PanelWindow {
    id: root

    property var targetScreen: null
    property real panelX: 0
    property real panelY: 0
    // A width <= 0 follows the content
    property real panelWidth: 0
    property real maxPanelHeight: Infinity
    property int padding: 0
    property color panelColor: Theme.hostSurface
    property color panelBorderColor: Theme.popupBorder
    // Values from DankMaterialShell's elevationLevel2 (Common/Theme.qml)
    property real shadowBlur: 8
    property real shadowOffset: 4
    property color shadowColor: Qt.rgba(0, 0, 0, 0.25)
    // "left" or "right": the panel slides in from that side of the screen; "" (default): it just appears
    property string slideFrom: ""
    // How far from that screen edge the slide is clipped, so the panel comes out from behind the bar there
    // (the popout is on a layer above the bar) instead of passing over it
    property real slideClip: 0
    // false: the owner closes it (e.g. binds visible) when dismissed() fires
    property bool closeOnDismiss: true
    property bool useFocusGrab: false

    property bool contentWarm: false
    property bool presented: false
    // 0 hidden, 1 shown. Only this is animated and the panel's place comes from it, so a geometry change
    // (the window gets its size on the first open) moves the panel at once instead of sliding it. On close
    // it snaps back, as the window is already hidden.
    property real slideProgress: slideFrom === "" || presented ? 1 : 0

    Behavior on slideProgress {
        enabled: root.slideFrom !== "" && root.visible
        NumberAnimation {
            duration: Theme.animation.elementMoveEnter.duration
            easing.type: Theme.animation.elementMoveEnter.type
            easing.bezierCurve: Theme.animation.elementMoveEnter.bezierCurve
        }
    }
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
            // The grab must be switched on after the window is mapped, never bound to visible
            Qt.callLater(() => focusGrab.active = root.useFocusGrab && Compositor.useHyprlandFocusGrab);
        } else {
            focusGrab.active = false;
            panelClosed();
        }
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
        id: slideArea

        x: root.slideFrom === "left" ? root.slideClip : 0
        width: parent.width - (root.slideFrom === "" ? 0 : root.slideClip)
        height: parent.height
        clip: root.slideFrom !== ""

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
            // Past the clip edge: the panel's width, its gap to that edge and room for its shadow
            // From the screen, not from this window: the window is 0 wide until the compositor sizes it,
            // which on the first open can be after the slide starts
            readonly property real hiddenOffset: root.slideFrom === "left" ? -(x + width + root.shadowBlur) : (root.targetScreen?.width ?? 0) - root.slideClip - x + root.shadowBlur

            x: root.panelX - slideArea.x
            y: root.panelY
            width: panel.width
            height: panel.height
            opacity: root.slideFrom === "" || root.presented ? 1 : 0

            Behavior on opacity {
                enabled: root.slideFrom !== "" && root.visible
                NumberAnimation {
                    duration: Theme.animation.elementMoveFast.duration
                    easing.type: Theme.animation.elementMoveFast.type
                    easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                }
            }

            transform: Translate {
                x: (1 - root.slideProgress) * wrapper.hiddenOffset
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

                Item {
                    id: contentHolder
                    anchors.fill: parent
                    anchors.margins: root.padding
                }
            }
        }
    }
}
