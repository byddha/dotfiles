import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Config"
import "../Utils"

PanelWindow {
    id: panel

    required property ShellScreen screen

    signal dismissed

    implicitWidth: screen.width
    implicitHeight: screen.height
    color: "transparent"  // Invisible overlay
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive  // Enables keyboard events

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    function show() {
        visible = true;
        Logger.info("Panel shown");
    }

    function hide() {
        Logger.info("Panel hiding");
        visible = false;
        dismissed();
    }

    // Catch clicks outside menu content
    MouseArea {
        anchors.fill: parent
        z: 0  // Behind content
        onClicked: {
            Logger.info("Clicked outside, closing");
            panel.hide();
        }
    }

    // Content container (menus go here with higher z-index)
    // Children of this Item will receive clicks/events before the background MouseArea
    property alias contentItem: contentContainer

    Item {
        id: contentContainer
        anchors.fill: parent
        z: 100

        // This is where child content (TrayMenu) will be placed
    }
}
