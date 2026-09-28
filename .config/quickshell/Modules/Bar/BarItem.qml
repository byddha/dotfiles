import QtQuick
import "../../Config"

/**
 * BarItem - One interactive thing in the bar: its fill, states, content box and tooltip.
 *
 * Content is laid out in a row on a horizontal bar and in a column on a vertical one.
 * The pointer area covers the bar's whole thickness and the gap to the screen edge, so a
 * pointer pushed against the edge still hits the item.
 */
Item {
    id: root

    default property alias content: box.data
    readonly property bool vertical: BarLayout.vertical

    property bool iconOnly: false
    property int spacing: vertical ? 4 : 6
    // Filled as on hover, e.g. while its popout is open
    property bool highlighted: false
    // An accent line on the side that faces the windows
    property bool marked: false
    property color fill: "transparent"
    property color hoverFill: Theme.colLayer2
    property color pressedFill: Theme.colLayer3

    property alias tooltipTitle: tooltip.title
    property alias tooltipKeys: tooltip.keys
    property alias tooltipDetail: tooltip.detail

    property alias acceptedButtons: pointer.acceptedButtons
    readonly property alias hovered: pointer.containsMouse
    readonly property alias pressed: pointer.pressed

    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: vertical ? BarLayout.itemSize : iconOnly ? BarLayout.itemSize : box.implicitWidth + 16
    implicitHeight: vertical ? Math.max(BarLayout.itemSize, box.implicitHeight + 14) : BarLayout.itemSize

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: root.pressed ? root.pressedFill : root.hovered || root.highlighted || root.marked ? root.hoverFill : root.fill

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        visible: root.marked
        color: Theme.primary
        radius: 1
        x: root.vertical ? (BarLayout.edge === "left" ? parent.width - 4 : 2) : 8
        y: root.vertical ? 8 : (BarLayout.edge === "top" ? parent.height - 4 : 2)
        width: root.vertical ? 2 : parent.width - 16
        height: root.vertical ? parent.height - 16 : 2
    }

    Grid {
        id: box

        anchors.centerIn: parent
        // One binding for the shape, so switching orientation never passes through a 1x1 grid
        columns: root.vertical ? 1 : Math.max(1, children.length)
        spacing: root.spacing
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
    }

    MouseArea {
        id: pointer

        // Under the content, so controls inside an item (media) take their own clicks
        z: -1

        readonly property real rest: (BarLayout.thickness - BarLayout.itemSize) / 2

        anchors.fill: parent
        anchors.topMargin: -(root.vertical ? 0 : rest + (BarLayout.edge === "top" ? BarLayout.gap : 0))
        anchors.bottomMargin: -(root.vertical ? 0 : rest + (BarLayout.edge === "bottom" ? BarLayout.gap : 0))
        anchors.leftMargin: -(root.vertical ? rest + (BarLayout.edge === "left" ? BarLayout.gap : 0) : 0)
        anchors.rightMargin: -(root.vertical ? rest + (BarLayout.edge === "right" ? BarLayout.gap : 0) : 0)
        hoverEnabled: true
        // Right and middle clicks are always taken: left to Qt Quick they can reach its context-menu path
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }

    BarTooltip {
        id: tooltip

        target: root
        shown: root.hovered && !root.pressed
    }
}
