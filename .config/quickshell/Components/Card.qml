import QtQuick
import "../Config"

Rectangle {
    id: root

    default property alias contentData: contentItem.data

    property bool collapsible: false
    property bool collapsed: false
    property string title: ""

    color: Theme.colLayer1
    radius: Theme.radiusBase

    // Animate how open the card is, not its height: content size changes then apply at once.
    readonly property real headerHeight: title !== "" ? titleText.height : 0
    property real openFraction: collapsed ? 0 : 1

    Behavior on openFraction {
        enabled: root.collapsible
        NumberAnimation {
            duration: Theme.animation.elementMoveFast.duration
            easing.type: Theme.animation.elementMoveFast.type
            easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
        }
    }

    implicitHeight: Theme.spacingBase * 2 + headerHeight + openFraction * ((headerHeight > 0 ? Theme.spacingBase : 0) + contentItem.implicitHeight)
    clip: true
    implicitWidth: contentColumn.implicitWidth + Theme.spacingBase * 2

    Column {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingBase
        spacing: Theme.spacingBase

        // Optional title header
        Item {
            width: parent.width
            height: root.title !== "" ? titleText.height : 0
            visible: root.title !== ""

            Text {
                id: titleText
                text: root.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase
                font.weight: Font.Medium
                color: Theme.textColor
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            // Collapse button
            Text {
                text: root.collapsed ? "" : ""
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textSecondary
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.collapsible

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.collapsed = !root.collapsed
                }
            }
        }

        // Content container
        Item {
            id: contentItem
            width: parent.width
            implicitHeight: childrenRect.height
            visible: root.openFraction > 0
            clip: true
        }
    }
}
