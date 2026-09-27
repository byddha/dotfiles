pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Wayland
import "../../../Config"
import "../../CalendarPanel"

BarPopup {
    id: calendarPopup

    WlrLayershell.namespace: "bidshell:calendar-popup"

    Rectangle {
        id: panelBg
        width: (contentLoader.item?.implicitWidth ?? 380) + Theme.spacingBase * 2
        height: (contentLoader.item?.implicitHeight ?? 400) + Theme.spacingBase * 2
        implicitWidth: width
        implicitHeight: height
        color: Theme.colLayer0
        radius: Theme.radiusWindow
        border.color: Theme.popupBorder
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
