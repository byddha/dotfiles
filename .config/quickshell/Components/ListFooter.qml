import QtQuick
import QtQuick.Layouts
import "../Config"

// Bottom bar of a tab: a count on the left, one action on the right. In a tab that runs bottom to
// top it is the top bar, with its line on the side that faces the list.
Item {
    id: root

    property string meta: ""
    property string actionText: ""
    property string actionIcon: ""
    property bool actionEnabled: true

    signal actionClicked

    Layout.fillWidth: true
    Layout.minimumHeight: implicitHeight
    implicitHeight: 44

    readonly property bool reversed: parent?.reversed ?? false

    Rectangle {
        y: root.reversed ? parent.height - height : 0
        width: parent.width
        height: 1
        color: Theme.outlineVariant
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 8
        spacing: Theme.spacingBase

        StyledText {
            Layout.fillWidth: true
            role: "secondary"
            text: root.meta
            font.pixelSize: Theme.fontSizeTiny
        }

        TextButton {
            visible: root.actionText !== ""
            enabled: root.actionEnabled
            text: root.actionText
            icon: root.actionIcon
            onClicked: root.actionClicked()
        }
    }
}
