import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Components"

ReversibleGrid {
    id: root

    // Sidebar is open; tabs refresh their data when shown
    property bool shown: false

    rowSpacing: 8
    reversed: Placement.sidebarReversed

    QuickToggles {
        Layout.fillWidth: true
    }

    QuickSliders {
        Layout.fillWidth: true
    }

    // The only part that gives up height when the sidebar hits the screen edge
    TabbedSection {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 200
        shown: root.shown
    }
}
