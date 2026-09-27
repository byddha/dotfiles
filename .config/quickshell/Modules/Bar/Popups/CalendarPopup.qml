pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Wayland
import "../../../Config"
import "../../../Components"
import "../../CalendarPanel"

Popout {
    id: calendarPopup

    WlrLayershell.namespace: "bidshell:calendar-popup"
    padding: Theme.spacingBase

    // Built with the popup (the owner recreates it on each open), so its size is known before it shows
    CalendarPanelContent {
        anchors.fill: parent
    }
}
