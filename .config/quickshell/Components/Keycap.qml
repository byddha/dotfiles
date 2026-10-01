import QtQuick
import "../Config"

Rectangle {
    property alias text: label.text
    // On a primary-filled button
    property bool onPrimary: false

    implicitWidth: Math.max(implicitHeight, label.implicitWidth + 10)
    implicitHeight: label.implicitHeight + 4
    radius: Theme.radiusSmall
    color: onPrimary ? Theme.alpha(Theme.primaryText, 0.14) : Theme.chipSurfaceNested

    Text {
        id: label

        anchors.centerIn: parent
        color: parent.onPrimary ? Theme.primaryText : Theme.textSecondary
        font.family: Theme.fontUi
        font.pixelSize: 11
        font.weight: Font.Medium
    }
}
