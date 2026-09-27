pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Config"
import "../../../Components"
import "../../../Services"

ExpandableListItem {
    id: root

    required property var network

    active: network?.active ?? false
    icon: Icons.wifiOn
    title: network?.ssid ?? "Unknown network"
    subtitle: "Connected"
    subtitleVisible: network?.active ?? false
    badgeIcon: network?.isSecure ? "\u{f023}" : "" // lock
    actionText: network?.active ? "Disconnect" : "Connect"
    hideActionsWhenCollapsed: true
    extraContentVisible: network?.askingPassword ?? false
    extraContent: RowLayout {
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

    onActionClicked: {
        if (network?.active) {
            Network.disconnectWifiNetwork();
        } else {
            Network.connectToWifiNetwork(network);
        }
    }
}
