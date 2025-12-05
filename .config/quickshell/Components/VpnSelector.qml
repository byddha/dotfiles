import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Config"
import "../Services"
import "../Utils"

// Inline VPN selector that expands below the quick toggles
Rectangle {
    id: root

    property bool expanded: false
    property bool showFortiPassword: false

    visible: expanded
    implicitHeight: expanded ? content.implicitHeight + Theme.spacingBase * 2 : 0
    color: Theme.colLayer1
    radius: Theme.radiusBase

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    clip: true

    // Reset password field when collapsed
    onExpandedChanged: {
        if (!expanded) {
            showFortiPassword = false;
            passwordField.text = "";
        }
    }

    // Auto-collapse on successful connection
    Connections {
        target: Vpn
        function onFortiConnectedChanged() {
            if (Vpn.fortiConnected) {
                root.expanded = false;
            }
        }
        function onMullvadConnectedChanged() {
            if (Vpn.mullvadConnected) {
                root.expanded = false;
            }
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Theme.spacingBase
        spacing: Theme.spacingSmall

        // Mullvad option
        Rectangle {
            readonly property bool locked: Vpn.fortiConnected
            Layout.fillWidth: true
            height: 44
            radius: Theme.radiusSmall
            opacity: locked ? 0.4 : 1.0
            color: mullvadMouse.containsMouse && !locked ? Theme.colLayer2 : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingBase
                anchors.rightMargin: Theme.spacingBase
                spacing: Theme.spacingBase

                // Connection indicator
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: Vpn.mullvadConnected ? Theme.primary : Theme.textSecondary
                }

                Text {
                    text: "Mullvad"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBase
                    color: Theme.textColor
                    Layout.fillWidth: true
                }

                Text {
                    text: Vpn.mullvadConnected ? Vpn.mullvadCity || "Connected" : "Disconnected"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textSecondary
                }
            }

            MouseArea {
                id: mullvadMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: parent.locked ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                onClicked: {
                    if (parent.locked) return;
                    Vpn.toggleMullvad();
                    root.expanded = false;
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.alpha(Theme.textColor, 0.1)
        }

        // FortiVPN option
        Rectangle {
            readonly property bool locked: Vpn.mullvadConnected
            Layout.fillWidth: true
            height: 44
            radius: Theme.radiusSmall
            opacity: locked ? 0.4 : 1.0
            color: fortiMouse.containsMouse && !locked ? Theme.colLayer2 : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingBase
                anchors.rightMargin: Theme.spacingBase
                spacing: Theme.spacingBase

                // Connection indicator
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: Vpn.fortiConnectionFailed ? Theme.accentRed : (Vpn.fortiConnected ? Theme.primary : Theme.textSecondary)
                }

                Text {
                    text: "FortiVPN"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBase
                    color: Theme.textColor
                    Layout.fillWidth: true
                }

                Text {
                    text: Vpn.fortiConnectionFailed ? "Failed" : (Vpn.fortiConnected ? "Connected" : "Disconnected")
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Vpn.fortiConnectionFailed ? Theme.accentRed : Theme.textSecondary
                }
            }

            MouseArea {
                id: fortiMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: parent.locked ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                onClicked: {
                    if (parent.locked) return;
                    if (Vpn.fortiConnected) {
                        Vpn.disconnectForti();
                        root.expanded = false;
                    } else {
                        // Show password field
                        root.showFortiPassword = true;
                        passwordField.forceActiveFocus();
                    }
                }
            }
        }

        // FortiVPN password input
        RowLayout {
            Layout.fillWidth: true
            visible: root.showFortiPassword
            spacing: Theme.spacingSmall

            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "FortiVPN Password"
                placeholderTextColor: Theme.textSecondary
                echoMode: TextInput.Password
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textColor

                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.colLayer0
                    border.color: passwordField.activeFocus ? Theme.primary : Theme.alpha(Theme.textColor, 0.2)
                    border.width: 1
                }

                onAccepted: {
                    if (text.length > 0) {
                        Vpn.connectFortiWithPassword(text);
                        text = "";
                        root.showFortiPassword = false;
                        // Don't collapse - let user see connection result
                    }
                }

                Keys.onEscapePressed: {
                    root.showFortiPassword = false;
                    text = "";
                }
            }

            Rectangle {
                width: 36
                height: 36
                radius: Theme.radiusSmall
                color: connectMouse.containsMouse ? Theme.primary : Theme.colLayer2

                Text {
                    anchors.centerIn: parent
                    text: Icons.chevronRight
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: 16
                    color: connectMouse.containsMouse ? Theme.primaryText : Theme.textColor
                }

                MouseArea {
                    id: connectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (passwordField.text.length > 0) {
                            Vpn.connectFortiWithPassword(passwordField.text);
                            passwordField.text = "";
                            root.showFortiPassword = false;
                            // Don't collapse - let user see connection result
                        }
                    }
                }
            }
        }
    }
}
