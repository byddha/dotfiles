import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Config"
import "../../../Components"
import "../../../Components/Notifications"
import "../../../Services"
import "../../../Utils"

ColumnLayout {
    id: root

    spacing: Theme.spacingBase

    onVisibleChanged: {
        if (!visible) {
            searchField.text = ""
            searchField.focus = false
        }
    }

    Connections {
        target: Settings
        function onSidebarVisibleChanged() {
            searchField.text = ""
            searchField.focus = false
        }
    }

    // Search field
    TextField {
        id: searchField
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        leftPadding: Theme.spacingBase
        placeholderText: "Search notifications..."
        font.pixelSize: Theme.fontSizeBase
        color: Theme.textColor
        placeholderTextColor: Theme.textSecondary
        verticalAlignment: Text.AlignVCenter
        background: Rectangle {
            radius: Theme.radiusBase
            color: Theme.colLayer1
            border.color: searchField.activeFocus ? Theme.primary : Theme.alpha(Theme.textColor, 0.1)
            border.width: 1
        }
    }

    // Notification list
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 100

        // Click to unfocus search field
        MouseArea {
            anchors.fill: parent
            onClicked: searchField.focus = false
            propagateComposedEvents: true
        }

        NotificationListView {
            id: notificationList
            anchors.fill: parent
            popup: false
            searchText: searchField.text
            visible: Notifications.list.length > 0
        }

        // Empty state
        Item {
            anchors.fill: parent
            visible: Notifications.list.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingBase

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No notifications"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBase
                    color: Theme.textSecondary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Icons.bell
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: 64
                    color: Theme.textSecondary
                }
            }
        }
    }

    // Bottom controls
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingBase / 2

        // Notification count (disabled, just for display)
        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: Theme.radiusBase
            color: Theme.colLayer1
            border.color: Theme.alpha(Theme.textColor, 0.1)
            border.width: 1

            StyledText {
                anchors.centerIn: parent
                text: `${Notifications.list.length} notification${Notifications.list.length === 1 ? '' : 's'}`
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
            }
        }

        // Clear all button
        Button {
            Layout.preferredWidth: 80
            text: "Clear All"
            font.pixelSize: Theme.fontSizeSmall
            enabled: Notifications.list.length > 0
            onClicked: {
                Notifications.discardAllNotifications()
                Logger.info("All notifications cleared")
            }
        }
    }

    Component.onCompleted: {
        Logger.info("Notification history tab loaded")
    }
}
