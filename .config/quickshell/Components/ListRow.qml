import QtQuick
import QtQuick.Layouts
import "../Config"
import "../Services"

// One row of a sidebar list: lead (32 box) · title / subtitle · trail, with an optional body shown when expanded
Rectangle {
    id: root

    property string leadIcon: ""
    property color leadColor: selected ? Theme.primary : Theme.textSecondary
    // Replaces leadIcon: status dot, logo, app icon
    property Component lead: null
    property string title: ""
    property string subtitle: ""
    property string subtitleIcon: ""
    property color subtitleColor: Theme.textSecondary
    property string trailText: ""
    property color trailColor: Theme.textSecondary
    property string trailIcon: ""
    // Replaces trailText / trailIcon / chevron
    property Component trail: null
    property bool expandable: false
    property bool expanded: false
    property Component body: null
    property bool selected: false
    property bool disabled: false

    readonly property bool twoLine: subtitle !== ""
    // As DMS SettingsRow: header height follows the subtitle unless the caller fixes it
    property real minHeight: twoLine ? 48 : 40
    readonly property bool showBody: expanded && body !== null

    signal clicked
    signal rightClicked

    implicitHeight: header.height + (showBody ? bodyLoader.implicitHeight + 8 : 0)
    radius: Theme.radiusBase
    opacity: disabled ? Theme.stateDisabled : 1
    color: {
        if (showBody)
            return selected ? Theme.alpha(Theme.primary, Theme.stateSelected) : Theme.chipSurface;
        if (selected)
            return Theme.alpha(Theme.primary, mouseArea.containsMouse && !disabled ? 0.18 : Theme.stateSelected);
        return "transparent";
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    Item {
        id: header
        width: parent.width
        height: Math.max(root.minHeight, headerRow.implicitHeight + 8)

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "transparent"

            StateLayer {
                visible: !root.disabled && !(root.selected && !root.showBody)
                hovered: mouseArea.containsMouse
                pressed: mouseArea.pressed
                hoverOpacity: root.showBody ? 0.04 : Theme.stateHover
            }
        }

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            spacing: 12

            Item {
                visible: root.lead !== null || root.leadIcon !== ""
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                Icon {
                    anchors.centerIn: parent
                    visible: root.lead === null
                    text: root.leadIcon
                    size: Theme.iconSizeLarge
                    color: root.leadColor

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                Loader {
                    anchors.centerIn: parent
                    active: root.lead !== null
                    sourceComponent: root.lead
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: Theme.fontSizeSmall
                    elide: Text.ElideRight
                }

                RowLayout {
                    visible: root.twoLine
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall

                    Icon {
                        visible: root.subtitleIcon !== ""
                        text: root.subtitleIcon
                        size: Theme.iconSizeSmall
                        color: root.subtitleColor
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.subtitle
                        font.pixelSize: Theme.fontSizeTiny
                        font.weight: Font.Normal
                        color: root.subtitleColor
                        elide: Text.ElideRight
                    }
                }
            }

            StyledText {
                visible: root.trail === null && root.trailText !== ""
                text: root.trailText
                font.pixelSize: Theme.fontSizeTiny
                font.weight: Font.Normal
                color: root.trailColor
            }

            Icon {
                visible: root.trail === null && (root.trailIcon !== "" || root.expandable)
                text: root.trailIcon !== "" ? root.trailIcon : root.expanded ? Lucide.chevronUp : Lucide.chevronDown
                color: root.selected ? Theme.primary : Theme.textSecondary
            }

            Loader {
                active: root.trail !== null
                visible: active
                sourceComponent: root.trail
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: root.disabled ? Qt.ForbiddenCursor : Qt.PointingHandCursor
            onClicked: mouse => {
                if (root.disabled)
                    return;
                if (mouse.button === Qt.RightButton) {
                    root.rightClicked();
                    return;
                }
                if (root.expandable)
                    root.expanded = !root.expanded;
                root.clicked();
            }
        }
    }

    Loader {
        id: bodyLoader
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 52
        anchors.rightMargin: 8
        active: root.showBody
        visible: active
        sourceComponent: root.body
    }
}
