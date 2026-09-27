import QtQuick
import QtQuick.Layouts
import "../Config"

Rectangle {
    id: root

    property bool active: false
    property bool expanded: false
    property int actionRowHeight: 36
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool subtitleVisible: false
    property string badgeIcon: ""
    property string actionText: ""
    property bool hideActionsWhenCollapsed: false
    // Optional row between the header and the action row, shown only while expanded
    property Component extraContent: null
    property bool extraContentVisible: false

    signal actionClicked

    implicitHeight: mainRow.implicitHeight + Theme.spacingBase * 2 + (expanded ? actionRowHeight + Theme.spacingBase + (extraContentVisible ? extraLoader.implicitHeight + Theme.spacingBase : 0) : 0)
    radius: Theme.radiusBase
    clip: true
    color: {
        if (active)
            return Theme.alpha(Theme.primary, 0.15);
        if (mouseArea.containsMouse)
            return Theme.colLayer2;
        return "transparent";
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingBase
        spacing: Theme.spacingBase

        RowLayout {
            id: mainRow
            Layout.fillWidth: true
            spacing: Theme.spacingBase

            Text {
                text: root.icon
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeBase + 4
                color: root.active ? Theme.primary : Theme.textColor

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: Theme.fontSizeBase
                    color: root.active ? Theme.primary : Theme.textColor
                    elide: Text.ElideRight

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.subtitleVisible
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                    text: root.subtitle
                }
            }

            Text {
                visible: root.badgeIcon !== ""
                text: root.badgeIcon
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textSecondary
            }

            Text {
                text: root.expanded ? "\u{f077}" : "\u{f078}" // chevron up/down
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textSecondary
            }
        }

        Loader {
            id: extraLoader
            Layout.fillWidth: true
            active: root.extraContent !== null
            visible: root.expanded && root.extraContentVisible
            sourceComponent: root.extraContent
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.expanded || !root.hideActionsWhenCollapsed
            spacing: Theme.spacingBase
            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: root.actionText
                onClicked: root.actionClicked()
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: mainRow.implicitHeight + Theme.spacingBase * 2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded
    }
}
