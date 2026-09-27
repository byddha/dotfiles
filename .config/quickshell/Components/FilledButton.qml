import QtQuick
import QtQuick.Layouts
import "../Config"

// Only for the main action of an expanded row (Connect, submit)
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    readonly property bool iconOnly: text === ""

    signal clicked

    implicitWidth: iconOnly ? 36 : row.implicitWidth + 32
    implicitHeight: iconOnly ? 36 : 32
    radius: Theme.radiusBase
    color: Theme.primary

    StateLayer {
        primaryFill: true
        hovered: mouseArea.containsMouse
        pressed: mouseArea.pressed
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingBase

        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: Theme.fontFamilyGlyphs
            font.pixelSize: 16
            color: Theme.primaryText
        }

        StyledText {
            visible: !root.iconOnly
            text: root.text
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.primaryText
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
