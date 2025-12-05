import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../Config"
import "../../Services"
import "."

ScrollView {
    id: root

    property bool popup: false
    property string searchText: ""
    property alias implicitHeight: columnLayout.implicitHeight

    function matchesSearch(notif, query) {
        if (!query) return true
        const lowerQuery = query.toLowerCase()
        const summary = (notif.summary || "").toLowerCase()
        const body = (notif.body || "").toLowerCase()
        return summary.includes(lowerQuery) || body.includes(lowerQuery)
    }

    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
        id: columnLayout
        anchors {
            left: parent.left
            right: parent.right
            // For popup mode: anchor to bottom to stack upward
            // For sidebar mode: anchor to top (default behavior)
            bottom: root.popup ? parent.bottom : undefined
            top: root.popup ? undefined : parent.top
        }
        spacing: 4

        // Top spacer for popup border visibility
        Item {
            Layout.preferredHeight: root.popup ? 6 : 0
            visible: root.popup
        }

        Repeater {
            model: ScriptModel {
                // Show individual notifications sorted by time (most recent first)
                values: {
                    const list = root.popup ? Notifications.popupList : Notifications.list.slice().reverse()
                    if (!root.searchText) return list
                    return list.filter(notif => root.matchesSearch(notif, root.searchText))
                }
            }

            NotificationItem {
                required property var modelData
                Layout.fillWidth: true
                notificationObject: modelData
                popup: root.popup
            }
        }
    }
}
