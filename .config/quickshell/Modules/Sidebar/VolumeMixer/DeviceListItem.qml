import QtQuick
import QtQuick.Layouts
import "../../../Config"
import "../../../Components"
import "../../../Services"

Rectangle {
    id: root

    required property string deviceName
    required property bool isSelected
    signal clicked()

    implicitHeight: 32
    radius: Theme.radiusBase
    color: {
        if (isSelected) return Theme.alpha(Theme.primary, 0.15)
        if (mouseArea.containsMouse) return Theme.colLayer2
        return "transparent"
    }

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingBase
        anchors.rightMargin: Theme.spacingBase
        spacing: Theme.spacingBase

        // Device icon
        Text {
            text: Icons.device
            font.family: Theme.fontFamilyIcons
            font.pixelSize: Theme.fontSizeBase + 2
            color: root.isSelected ? Theme.primary : Theme.textColor

            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        // Device name
        StyledText {
            Layout.fillWidth: true
            text: root.deviceName
            font.pixelSize: Theme.fontSizeBase
            color: root.isSelected ? Theme.primary : Theme.textColor
            elide: Text.ElideRight

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        // Checkmark (only visible when selected)
        Text {
            visible: root.isSelected
            text: Icons.checkmark
            font.family: Theme.fontFamilyIcons
            font.pixelSize: Theme.fontSizeBase
            color: Theme.primary

            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.isSelected ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (!root.isSelected) {
                root.clicked()
            }
        }
    }
}
