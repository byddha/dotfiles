import QtQuick
import "../../Config"

// The bar's sections: start (left or top), center and end (right or bottom)
Item {
    id: root

    readonly property bool vertical: BarLayout.vertical
    readonly property int padding: 6

    Section {
        id: endSection

        x: root.vertical ? Math.round((root.width - width) / 2) : root.width - width - root.padding
        y: root.vertical ? root.height - height - root.padding : Math.round((root.height - height) / 2)

        PowerButton {}
    }

    component Section: Grid {
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
        spacing: 2
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
    }
}
