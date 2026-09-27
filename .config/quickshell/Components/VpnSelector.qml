import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Config"
import "../Services"

// Inline VPN selector that expands below the quick toggles
Rectangle {
    id: root

    property bool expanded: false
    property bool showFortiPassword: false

    // Animate how open the selector is, not its height: content size changes then apply at once.
    property real openFraction: expanded ? 1 : 0

    Behavior on openFraction {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    visible: openFraction > 0
    implicitHeight: openFraction * (content.implicitHeight + Theme.spacingBase * 2)
    color: Theme.colLayer1
    radius: Theme.radiusBase

    clip: true

    function submitFortiPassword() {
        if (passwordField.text.length > 0) {
            Vpn.connectFortiWithPassword(passwordField.text);
            passwordField.text = "";
            root.showFortiPassword = false;
            // Don't collapse - let user see connection result
        }
    }

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

        VpnRow {
            name: "Mullvad"
            locked: Vpn.fortiConnected
            indicatorColor: Vpn.mullvadConnected ? Theme.primary : Theme.textSecondary
            status: Vpn.mullvadConnected ? Vpn.mullvadCity || "Connected" : "Disconnected"
            onClicked: {
                Vpn.toggleMullvad();
                root.expanded = false;
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.alpha(Theme.textColor, 0.1)
        }

        VpnRow {
            name: "FortiVPN"
            locked: Vpn.mullvadConnected
            indicatorColor: Vpn.fortiConnectionFailed ? Theme.accentRed : (Vpn.fortiConnected ? Theme.primary : Theme.textSecondary)
            status: Vpn.fortiConnectionFailed ? "Failed" : (Vpn.fortiConnected ? "Connected" : "Disconnected")
            statusColor: Vpn.fortiConnectionFailed ? Theme.accentRed : Theme.textSecondary
            onClicked: {
                if (Vpn.fortiConnected) {
                    Vpn.disconnectForti();
                    root.expanded = false;
                } else {
                    root.showFortiPassword = true;
                    passwordField.forceActiveFocus();
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

                onAccepted: root.submitFortiPassword()

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
                    onClicked: root.submitFortiPassword()
                }
            }
        }
    }

    component VpnRow: Rectangle {
        id: vpnRow

        property string name
        property string status
        property color indicatorColor
        property color statusColor: Theme.textSecondary
        property bool locked

        signal clicked

        Layout.fillWidth: true
        height: 44
        radius: Theme.radiusSmall
        opacity: locked ? 0.4 : 1.0
        color: rowMouse.containsMouse && !locked ? Theme.colLayer2 : "transparent"

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
                color: vpnRow.indicatorColor
            }

            Text {
                text: vpnRow.name
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textColor
                Layout.fillWidth: true
            }

            Text {
                text: vpnRow.status
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: vpnRow.statusColor
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: vpnRow.locked ? Qt.ForbiddenCursor : Qt.PointingHandCursor
            onClicked: {
                if (!vpnRow.locked)
                    vpnRow.clicked();
            }
        }
    }
}
