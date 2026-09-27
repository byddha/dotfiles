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

    implicitHeight: contentColumn.implicitHeight + Theme.spacingBase * 2
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
            visible: !root.collapsed
            clip: true

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Theme.animation.elementMoveFast.duration
                    easing.type: Theme.animation.elementMoveFast.type
                    easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                }
            }
        }
    }

    // Animated height for collapse
    Behavior on implicitHeight {
        enabled: root.collapsible
        NumberAnimation {
            duration: Theme.animation.elementMoveFast.duration
            easing.type: Theme.animation.elementMoveFast.type
            easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
        }
    }
}
