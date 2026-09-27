import QtQuick
import QtQuick.Layouts
import "../Config"

Item {
    id: root

    property string text: ""
    property string icon: ""
    property string hint: ""

    implicitHeight: column.implicitHeight + 64

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: Theme.spacingBase

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 48
            implicitHeight: 48
            radius: 24
            color: Theme.colLayer2

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.fontFamilyGlyphs
                font.pixelSize: 20
                color: Theme.textSecondary
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.text
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.textColor
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            visible: root.hint !== ""
            text: root.hint
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.textSecondary
        }
    }
}
