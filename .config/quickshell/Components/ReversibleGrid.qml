import QtQuick
import QtQuick.Layouts

/**
 * ReversibleGrid - A GridLayout that can fill its rows from the bottom up, for panels anchored to the
 * bottom of the screen: reversed, the first child lands in the last row. With one column (the
 * default) it is a ColumnLayout that can run either way.
 *
 * Children are placed by their index, so Repeater items and children that show or hide later need
 * nothing extra: the layout skips hidden ones, and rows with nothing visible take no room.
 */
GridLayout {
    id: root

    property bool reversed: false

    function place() {
        const rows = Math.ceil(children.length / columns);
        for (let i = 0; i < children.length; i++) {
            const row = Math.floor(i / columns);
            children[i].Layout.row = reversed ? rows - 1 - row : row;
            children[i].Layout.column = i % columns;
        }
    }

    columns: 1
    rowSpacing: 0
    columnSpacing: 0

    onChildrenChanged: place()
    onReversedChanged: place()
    onColumnsChanged: place()
}
