import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Components"

// A state without a level (power profile): its icon in the accent block, then its name
Item {
    id: root

    required property string icon
    required property string label

    readonly property real iconBlock: 24 + Theme.spacingBase * 2

    implicitWidth: row.implicitWidth + Theme.elevationMargin * 2
    implicitHeight: root.iconBlock + Theme.elevationMargin * 2

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Rectangle {
            color: Theme.primary
            topLeftRadius: Theme.radiusBase
            bottomLeftRadius: Theme.radiusBase
            Layout.preferredWidth: root.iconBlock
            Layout.preferredHeight: root.iconBlock

            Icon {
                anchors.centerIn: parent
                text: root.icon
                size: Theme.iconSizeLarge
                color: Theme.hostSurface
            }
        }

        Rectangle {
            color: Theme.alpha(Theme.hostSurface, 0.95)
            border.width: 1
            border.color: Theme.chipSurface
            topRightRadius: Theme.radiusBase
            bottomRightRadius: Theme.radiusBase
            Layout.preferredWidth: name.implicitWidth + Theme.spacingLarge * 2
            Layout.preferredHeight: root.iconBlock

            StyledText {
                id: name
                anchors.centerIn: parent
                text: root.label
                font.pixelSize: Theme.fontSizeLarge
            }
        }
    }
}
