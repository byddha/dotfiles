import QtQuick
import QtQuick.Layouts
import "../Config"

Item {
    id: root

    property string text: ""
    property string meta: ""
    property string metaIcon: ""
    property color metaColor: Theme.textSecondary
    property bool first: false

    Layout.fillWidth: true
    Layout.topMargin: first ? 0 : 12
    implicitHeight: 28

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: Theme.spacingSmall

        StyledText {
            Layout.fillWidth: true
            text: root.text.toUpperCase()
            font.pixelSize: Theme.fontSizeTiny
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            color: Theme.textSecondary
        }

        Text {
            visible: root.metaIcon !== ""
            text: root.metaIcon
            font.family: Theme.fontFamilyGlyphs
            font.pixelSize: 16
            color: root.metaColor
        }

        StyledText {
            visible: root.meta !== ""
            text: root.meta
            font.pixelSize: Theme.fontSizeTiny
            color: root.metaColor
        }
    }
}
