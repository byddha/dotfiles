import QtQuick
import QtQuick.Layouts
import "../../../Config"
import "../../../Components"
import "../../../Components/Notifications"
import "../../../Services"

ReversibleGrid {
    id: root

    property bool shown: false
    readonly property int count: Notifications.list.length

    reversed: Placement.sidebarReversed

    // The tab stays loaded, so start each visit with an empty search
    onShownChanged: {
        if (!shown)
            searchField.text = "";
    }

    InputField {
        id: searchField
        Layout.fillWidth: true
        Layout.margins: 12
        // The smaller gap faces the list
        Layout.topMargin: root.reversed ? 8 : 12
        Layout.bottomMargin: root.reversed ? 12 : 8
        visible: root.count > 0
        icon: Lucide.search
        placeholderText: "Search notifications…"
    }

    NotificationListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.topMargin: root.reversed ? 12 : 0
        Layout.bottomMargin: root.reversed ? 0 : 12
        visible: root.count > 0
        searchText: searchField.text
        reversed: root.reversed
    }

    EmptyState {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.count === 0
        text: "No notifications"
        icon: Lucide.bell
    }

    ListFooter {
        visible: root.count > 0
        meta: searchField.text ? `${list.count} of ${root.count}` : `${root.count} notification${root.count === 1 ? "" : "s"}`
        actionText: "Clear All"
        actionIcon: Lucide.listX
        onActionClicked: Notifications.discardAllNotifications()
    }
}
