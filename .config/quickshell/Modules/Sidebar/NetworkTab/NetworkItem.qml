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
            implicitWidth: 20
            implicitHeight: 20

            // Unfilled arcs under the filled ones
            Text {
                anchors.centerIn: parent
                text: Icons.wifiStrengthOutline
                font.family: Theme.fontFamilyGlyphs
                font.pixelSize: 20
                color: Theme.alpha(Theme.textSecondary, 0.3)
            }

            Text {
                anchors.centerIn: parent
                text: [Icons.wifiStrength1, Icons.wifiStrength2, Icons.wifiStrength3, Icons.wifiStrength4][root.bars - 1]
                font.family: Theme.fontFamilyGlyphs
                font.pixelSize: 20
                color: root.selected ? Theme.primary : Theme.textSecondary
            }
        }
    }
    title: network?.ssid ?? "Unknown network"
    subtitle: network?.active ? "Connected" : network?.isSecure ? "Secured" : "Open"
    subtitleIcon: !network?.active && network?.isSecure ? Icons.lock : ""
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
                    icon: Icons.lock
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
                    icon: Icons.arrowRight
                    onClicked: passwordField.submit()
                }
            }

            StyledText {
                Layout.topMargin: 6
                text: "Enter to connect"
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.textSecondary
            }
        }
    }
}
