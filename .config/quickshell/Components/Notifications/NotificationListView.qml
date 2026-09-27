import QtQuick
import QtQuick.Controls
import Quickshell
import "../../Config"
import "../../Services"

// Notification history list. Transitions follow DMS HistoryNotificationList (DankCommon ListViewTransitions):
// fade in on add (with a small stagger), fade out on remove, slide displaced cards.
ListView {
    id: root

    property string searchText: ""
    // DMS expressiveDurations.fast at the default 250 ms animation base (0.4x), and its 3% add stagger.
    readonly property int fastDuration: 100
    readonly property int staggerMs: 8

    function matchesSearch(notif, query) {
        if (!query)
            return true;
        const lowerQuery = query.toLowerCase();
        const summary = (notif.summary || "").toLowerCase();
        const body = (notif.body || "").toLowerCase();
        return summary.includes(lowerQuery) || body.includes(lowerQuery);
    }

    clip: true
    // Natural height is the whole list; a layout that gives it less makes it scroll
    implicitHeight: contentHeight
    // DMS groupedListGap: history cards form one grouped list.
    spacing: 2
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {
        id: bar
        policy: root.contentHeight > root.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        rightPadding: 3
        topPadding: 3
        bottomPadding: 3
        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Theme.alpha(Theme.outline, bar.hovered || bar.pressed ? 0.6 : 0.35)
        }
        background: null
    }

    // Most recent first.
    model: ScriptModel {
        values: {
            const list = Notifications.list.slice().reverse();
            if (!root.searchText)
                return list;
            return list.filter(notif => root.matchesSearch(notif, root.searchText));
        }
    }

    delegate: NotificationCard {
        required property var modelData
        required property int index
        width: ListView.view.width
        notificationObject: modelData
        firstInGroup: index === 0
        lastInGroup: index === root.count - 1
    }

    add: Transition {
        id: addTransition

        SequentialAnimation {
            PropertyAction {
                property: "opacity"
                value: 0
            }
            PauseAnimation {
                duration: Math.max(0, Math.min(addTransition.ViewTransition.index - (addTransition.ViewTransition.targetIndexes[0] ?? 0), 8)) * root.staggerMs
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: root.fastDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
            }
        }
    }

    remove: Transition {
        NumberAnimation {
            property: "opacity"
            to: 0
            duration: root.fastDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
        }
    }

    displaced: Transition {
        NumberAnimation {
            property: "y"
            duration: root.fastDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
        }
        NumberAnimation {
            property: "opacity"
            to: 1
            duration: root.fastDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
        }
    }
}
