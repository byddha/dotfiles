pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../Config"
import "../../../Components"
import "../../../Services"

ListRow {
    id: root

    required property var network

    readonly property int bars: {
        const s = network?.strength ?? 0;
        return s >= 75 ? 4 : s >= 50 ? 3 : s >= 25 ? 2 : 1;
    }

    lead: Component {
        Item {
            implicitWidth: Theme.iconSizeLarge
            implicitHeight: Theme.iconSizeLarge

            // Unfilled arcs under the filled ones
            Icon {
                text: Lucide.wifi
                size: Theme.iconSizeLarge
                color: Theme.alpha(Theme.textSecondary, 0.3)
            }

            Icon {
                text: [Lucide.wifiZero, Lucide.wifiLow, Lucide.wifiHigh, Lucide.wifi][root.bars - 1]
                size: Theme.iconSizeLarge
                color: root.selected ? Theme.primary : Theme.textSecondary
            }
        }
    }
    title: network?.ssid ?? "Unknown network"
    subtitle: network?.active ? "Connected" : network?.isSecure ? "Secured" : "Open"
    subtitleIcon: !network?.active && network?.isSecure ? Lucide.lock : ""
    selected: network?.active ?? false
    expandable: true
    body: network?.active ? disconnectBody : network?.askingPassword ? passwordBody : connectBody

    // A password request opens the row
    Connections {
        target: root.network
        function onAskingPasswordChanged() {
            if (root.network.askingPassword)
                root.expanded = true;
        }
    }

    Component {
        id: connectBody
        RowLayout {
            FilledButton {
                text: "Connect"
                onClicked: Network.connectToWifiNetwork(root.network)
            }
        }
    }

    Component {
        id: disconnectBody
        RowLayout {
            TextButton {
                text: "Disconnect"
                onClicked: {
                    Network.disconnectWifiNetwork();
                    root.expanded = false;
                }
            }
        }
    }

    Component {
        id: passwordBody
        ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingBase

                InputField {
                    id: passwordField
                    Layout.fillWidth: true
                    inRow: true
                    icon: Lucide.lock
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    consumeEscape: true
                    onAccepted: submit()
                    onEscapePressed: root.expanded = false
                    Component.onCompleted: focusInput()

                    function submit() {
                        if (text.length === 0)
                            return;
                        Network.changePassword(root.network, text);
                        text = "";
                    }
                }

                FilledButton {
                    icon: Lucide.arrowRight
                    onClicked: passwordField.submit()
                }
            }

            StyledText {
                Layout.topMargin: 6
                role: "secondary"
                text: "Enter to connect"
                font.pixelSize: Theme.fontSizeTiny
            }
        }
    }
}
