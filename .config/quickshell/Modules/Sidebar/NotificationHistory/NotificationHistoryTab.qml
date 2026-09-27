import QtQuick
import QtQuick.Layouts
import "../../../Config"
import "../../../Components"
import "../../../Components/Notifications"
import "../../../Services"

ColumnLayout {
    id: root

    property bool shown: false
    readonly property int count: Notifications.list.length

    spacing: 0

    // The tab stays loaded, so start each visit with an empty search
    onShownChanged: {
        if (!shown)
            searchField.text = "";
    }

    InputField {
        id: searchField
        Layout.fillWidth: true
        Layout.margins: 12
        Layout.bottomMargin: 8
        visible: root.count > 0
        icon: Icons.magnify
        placeholderText: "Search notifications…"
    }

    NotificationListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.bottomMargin: 12
        visible: root.count > 0
        searchText: searchField.text
    }

    EmptyState {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.count === 0
        text: "No notifications"
        icon: Icons.bell
    }

    ListFooter {
        visible: root.count > 0
        meta: searchField.text ? `${list.count} of ${root.count}` : `${root.count} notification${root.count === 1 ? "" : "s"}`
        actionText: "Clear All"
        actionIcon: Icons.clearAll
        onActionClicked: Notifications.discardAllNotifications()
    }
}
