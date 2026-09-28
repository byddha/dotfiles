import QtQuick
import "../../Config"

Rectangle {
    property alias text: label.text

    implicitWidth: label.implicitWidth + 10
    implicitHeight: label.implicitHeight + 4
    radius: 4
    color: Theme.colLayer3

    Text {
        id: label

        anchors.centerIn: parent
        color: Theme.textSecondary
        font.family: Theme.fontUi
        font.pixelSize: 11
        font.weight: Font.Medium
    }
}
