import QtQuick
import "../../Config"

Item {
    implicitWidth: BarLayout.vertical ? BarLayout.dividerLength : 1 + BarLayout.dividerMargin * 2
    implicitHeight: BarLayout.vertical ? 1 + BarLayout.dividerMargin * 2 : BarLayout.dividerLength

    Rectangle {
        anchors.centerIn: parent
        width: BarLayout.vertical ? BarLayout.dividerLength : 1
        height: BarLayout.vertical ? 1 : BarLayout.dividerLength
        color: Theme.outlineVariant
    }
}
