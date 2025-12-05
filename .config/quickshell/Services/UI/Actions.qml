pragma Singleton

import QtQuick
import Quickshell
import "../../Config"
import "../../Utils"

Singleton {
    id: root

    function launchColorPicker() {
        Settings.sidebarVisible = false;
        colorPickerTimer.start();
    }

    Timer {
        id: colorPickerTimer
        interval: 300
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["hyprpicker", "-a"]);
            Logger.info("Color picker launched");
        }
    }
}
