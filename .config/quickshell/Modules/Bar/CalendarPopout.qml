import QtQuick
import Quickshell.Wayland
import "../../Config"
import "../CalendarPanel"

BarPopout {
    id: root

    WlrLayershell.namespace: "bidshell:calendar-popup"
    padding: Theme.spacingBase

    onPanelClosed: content.reset()

    CalendarPanelContent {
        id: content

        anchors.fill: parent
    }
}
