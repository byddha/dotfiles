import QtQuick
import QtQuick.Layouts
import "../Config"

// Bottom bar of a tab: a count on the left, one action on the right
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

    Rectangle {
        anchors.top: parent.top
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
            text: root.meta
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.textSecondary
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
