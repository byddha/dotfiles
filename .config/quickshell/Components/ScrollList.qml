import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Config"

// Vertical list that scrolls when its rows do not fit; thin scrollbar only while content overflows.
// Reversed, its children (whole sections, each still read top to bottom) run bottom to top: they
// stand on the bottom when they do not fill it, and the list opens scrolled to its bottom and stays
// there as rows come and go, until the user scrolls away.
Flickable {
    id: root

    default property alias rows: column.data
    property int padding: 12
    property int spacing: 2
    property bool reversed: false
    property bool followsEnd: true

    function toEnd() {
        if (reversed && followsEnd)
            contentY = Math.max(0, contentHeight - height);
    }

    clip: true
    contentWidth: width
    contentHeight: column.implicitHeight + padding * 2
    // Natural height is the whole list; a layout that gives it less makes it scroll
    implicitHeight: contentHeight
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    onMovementEnded: followsEnd = atYEnd
    onContentHeightChanged: toEnd()
    onHeightChanged: toEnd()
    onReversedChanged: toEnd()

    ReversibleGrid {
        id: column
        x: root.padding
        y: root.reversed ? Math.max(root.padding, root.height - implicitHeight - root.padding) : root.padding
        width: root.width - root.padding * 2
        rowSpacing: root.spacing
        reversed: root.reversed
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
