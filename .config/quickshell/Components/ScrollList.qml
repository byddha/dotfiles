import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Config"

// Vertical list that scrolls when its rows do not fit; thin scrollbar only while content overflows
Flickable {
    id: root

    default property alias rows: column.data
    property int padding: 12
    property int spacing: 2

    clip: true
    contentWidth: width
    contentHeight: column.implicitHeight + padding * 2
    // Natural height is the whole list; a layout that gives it less makes it scroll
    implicitHeight: contentHeight
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    ColumnLayout {
        id: column
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: root.spacing
    }

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
}
