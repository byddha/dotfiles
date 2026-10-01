import QtQuick
import QtQuick.Layouts
import "../Config"

// Children go into a column that fills the card, so the card's natural height comes from the
// layout (which only reads its children) and a stretched card simply gives the layout more room.
// Reversed, the column runs bottom to top (a sidebar anchored to the bottom).
Rectangle {
    id: root

    default property alias contentData: layout.data
    property int padding: 12
    property alias spacing: layout.rowSpacing
    property alias reversed: layout.reversed

    implicitHeight: layout.implicitHeight + padding * 2
    // Plain items have a minimum height of 0 in layouts; a card keeps its natural height unless told otherwise
    Layout.minimumHeight: implicitHeight
    radius: Theme.radiusWindow
    color: Theme.cardSurface
    border.width: 1
    border.color: Theme.outlineVariant

    ReversibleGrid {
        id: layout
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
