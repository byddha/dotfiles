import QtQuick
import QtQuick.Layouts
import "../../../Config"
import "../../../Components"
import "../../../Services"
import "../../../Utils"

Rectangle {
    id: root

    required property var device
    property bool expanded: false
    property int actionRowHeight: 36  // Fixed height for action row

    implicitHeight: mainRow.implicitHeight + Theme.spacingBase * 2 + (expanded ? actionRowHeight + Theme.spacingBase : 0)
    radius: Theme.radiusBase
    clip: true
    color: {
        if (device?.connected) return Theme.alpha(Theme.primary, 0.15)
        if (mouseArea.containsMouse) return Theme.colLayer2
        return "transparent"
    }

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingBase
        spacing: Theme.spacingBase

        // Main row: icon, name/status, expand arrow
        RowLayout {
            id: mainRow
            Layout.fillWidth: true
            spacing: Theme.spacingBase

            // Device icon
            Text {
                text: Bluetooth.getDeviceIcon(root.device?.icon ?? "")
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeBase + 4
                color: root.device?.connected ? Theme.primary : Theme.textColor

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            // Name and status column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                // Device name
                StyledText {
                    Layout.fillWidth: true
                    text: root.device?.name ?? "Unknown device"
                    font.pixelSize: Theme.fontSizeBase
                    color: root.device?.connected ? Theme.primary : Theme.textColor
                    elide: Text.ElideRight

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                // Status line: Connected/Paired + battery
                StyledText {
                    Layout.fillWidth: true
                    visible: (root.device?.connected || root.device?.paired) ?? false
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                    text: {
                        if (!root.device?.paired) return ""
                        let status = root.device?.connected ? "Connected" : "Paired"
                        if (root.device?.batteryAvailable) {
                            status += ` \u2022 ${Math.round(root.device.battery * 100)}%`
                        }
                        return status
                    }
                }
            }

            // Expand/collapse arrow
            Text {
                text: root.expanded ? "\u{f077}" : "\u{f078}" // chevron up/down
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textSecondary
            }
        }

        // Action buttons
        RowLayout {
            id: actionRow
            Layout.fillWidth: true
            spacing: Theme.spacingBase
            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }

            Item { Layout.fillWidth: true }

            // Connect/Disconnect button
            Button {
                text: root.device?.connected ? "Disconnect" : "Connect"
                onClicked: {
                    if (root.device?.connected) {
                        root.device.disconnect()
                    } else {
                        root.device.connect()
                    }
                }
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
