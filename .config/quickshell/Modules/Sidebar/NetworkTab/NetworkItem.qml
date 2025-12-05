import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Config"
import "../../../Components"
import "../../../Services"
import "../../../Utils"

Rectangle {
    id: root

    required property var network
    property bool expanded: false
    property int actionRowHeight: 36

    implicitHeight: mainRow.implicitHeight + Theme.spacingBase * 2 + (expanded ? (network.askingPassword ? passwordRow.implicitHeight + actionRowHeight + Theme.spacingBase * 2 : actionRowHeight + Theme.spacingBase) : 0)
    radius: Theme.radiusBase
    clip: true
    color: {
        if (network?.active) return Theme.alpha(Theme.primary, 0.15)
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

        // Main row: signal icon, name, lock icon
        RowLayout {
            id: mainRow
            Layout.fillWidth: true
            spacing: Theme.spacingBase

            // Signal strength icon
            Text {
                text: {
                    if (root.network.strength > 75) return Icons.wifiOn;
                    if (root.network.strength > 50) return Icons.wifiOn;
                    if (root.network.strength > 25) return Icons.wifiOn;
                    return Icons.wifiOn;
                }
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeBase + 4
                color: root.network?.active ? Theme.primary : Theme.textColor

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            // Network name and status
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.network?.ssid ?? "Unknown network"
                    font.pixelSize: Theme.fontSizeBase
                    color: root.network?.active ? Theme.primary : Theme.textColor
                    elide: Text.ElideRight

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.network?.active
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textSecondary
                    text: "Connected"
                }
            }

            // Lock icon for secured networks
            Text {
                visible: root.network?.isSecure ?? false
                text: "\u{f023}" // lock icon
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textSecondary
            }

            // Expand/collapse arrow
            Text {
                text: root.expanded ? "\u{f077}" : "\u{f078}"
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textSecondary
            }
        }

        // Password input row (visible when asking for password)
        RowLayout {
            id: passwordRow
            Layout.fillWidth: true
            visible: root.expanded && root.network?.askingPassword
            spacing: Theme.spacingBase

            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "Password"
                echoMode: TextInput.Password
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase

                background: Rectangle {
                    radius: Theme.radiusBase
                    color: Theme.colLayer0
                    border.color: passwordField.activeFocus ? Theme.primary : Theme.alpha(Theme.textColor, 0.2)
                    border.width: 1
                }

                onAccepted: {
                    if (text.length > 0) {
                        Network.changePassword(root.network, text);
                        text = "";
                    }
                }
            }
        }

        // Action buttons
        RowLayout {
            id: actionRow
            Layout.fillWidth: true
            visible: root.expanded
            spacing: Theme.spacingBase
            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }

            Item { Layout.fillWidth: true }

            // Connect/Disconnect button
            Button {
                text: root.network?.active ? "Disconnect" : "Connect"
                onClicked: {
                    if (root.network?.active) {
                        Network.disconnectWifiNetwork();
                    } else {
                        Network.connectToWifiNetwork(root.network);
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
