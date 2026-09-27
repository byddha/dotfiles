import QtQuick
import QtQuick.Layouts
import "../../Config"

ColumnLayout {
    id: root

    // Sidebar is open; tabs refresh their data when shown
    property bool shown: false

    spacing: 8

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
