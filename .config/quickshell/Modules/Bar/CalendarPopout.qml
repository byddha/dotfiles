import QtQuick
import Quickshell.Wayland
import "../../Config"
import "../CalendarPanel"

BarPopout {
    WlrLayershell.namespace: "bidshell:calendar-popup"
    padding: Theme.spacingBase

    CalendarPanelContent {
        anchors.fill: parent
    }
}
