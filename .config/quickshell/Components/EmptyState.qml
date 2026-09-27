import QtQuick
import QtQuick.Layouts
import "../Config"

Item {
    id: root

    property string text: ""
    property string icon: ""

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacingBase

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBase
            color: Theme.textSecondary
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.family: Theme.fontFamilyIcons
            font.pixelSize: 64
            color: Theme.textSecondary
        }
    }
}
