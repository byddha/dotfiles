import QtQuick
import "../../Config"

Item {
    implicitWidth: BarLayout.vertical ? 16 : 13
    implicitHeight: BarLayout.vertical ? 13 : 16

    Rectangle {
        anchors.centerIn: parent
        width: BarLayout.vertical ? 16 : 1
        height: BarLayout.vertical ? 1 : 16
        color: Theme.outlineVariant
    }
}
