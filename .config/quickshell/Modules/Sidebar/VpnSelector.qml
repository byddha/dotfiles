import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Components"
import "../../Services"

// VPN list under the toggle grid; only one VPN can be connected at a time
ColumnLayout {
    id: root

    property bool expanded: false

    visible: expanded
    spacing: 2

    onExpandedChanged: {
        if (!expanded)
            fortiRow.expanded = false;
    }

    Connections {
        target: Vpn
        function onFortiConnectedChanged() {
            if (Vpn.fortiConnected)
                root.expanded = false;
        }
        function onMullvadConnectedChanged() {
            if (Vpn.mullvadConnected)
                root.expanded = false;
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 12
        Layout.bottomMargin: 6
        implicitHeight: 1
        color: Theme.outlineVariant
    }

    ListRow {
        Layout.fillWidth: true
        // Inset so the row hover lines up with the tiles
        Layout.leftMargin: -4
        Layout.rightMargin: -4
        lead: Component {
            StatusDot {
                on: Vpn.mullvadConnected
            }
        }
        title: "Mullvad"
        subtitle: {
            if (Vpn.fortiConnected)
                return "Disconnect FortiVPN first";
            if (Vpn.mullvadBusy)
                return Vpn.disconnecting ? "Disconnecting…" : "Connecting…";
            if (!Vpn.mullvadConnected)
                return "Disconnected";
            return [Vpn.mullvadCity, Vpn.mullvadCountry].filter(s => s).join(", ") || "Connected";
        }
        trailText: Vpn.mullvadConnected && !Vpn.mullvadBusy ? "Connected" : ""
        trailColor: Theme.primary
        selected: Vpn.mullvadConnected
        disabled: Vpn.fortiConnected || Vpn.fortiBusy
        onClicked: {
            Vpn.toggleMullvad();
            root.expanded = false;
        }
    }

    ListRow {
        id: fortiRow
        Layout.fillWidth: true
        Layout.leftMargin: -4
        Layout.rightMargin: -4
        lead: Component {
            StatusDot {
                on: Vpn.fortiConnected
                failed: Vpn.fortiConnectionFailed
            }
        }
        title: "FortiVPN"
        subtitle: {
            if (Vpn.mullvadConnected)
                return "Disconnect Mullvad first";
            if (Vpn.fortiBusy)
                return Vpn.fortiDisconnecting ? "Disconnecting…" : "Connecting…";
            if (Vpn.fortiConnectionFailed)
                return "Failed";
            return Vpn.fortiConnected ? Vpn.fortiUptime : "Disconnected";
        }
        subtitleColor: Vpn.fortiConnectionFailed && !Vpn.mullvadConnected ? Theme.accentRed : Theme.textSecondary
        selected: Vpn.fortiConnected
        disabled: Vpn.mullvadConnected || Vpn.mullvadBusy || Vpn.fortiBusy
        expandable: true
        body: Vpn.fortiConnected ? disconnectBody : passwordBody

        Component {
            id: disconnectBody
            RowLayout {
                TextButton {
                    text: "Disconnect"
                    onClicked: {
                        Vpn.disconnectForti();
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
                        error: Vpn.fortiConnectionFailed
                        consumeEscape: true
                        onAccepted: submit()
                        onEscapePressed: fortiRow.expanded = false
                        Component.onCompleted: focusInput()

                        function submit() {
                            if (text.length === 0)
                                return;
                            Vpn.connectFortiWithPassword(text);
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
                    text: "Enter to connect · Esc to cancel"
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.textSecondary
                }
            }
        }
    }

    component StatusDot: Rectangle {
        property bool on: false
        property bool failed: false
        width: 8
        height: 8
        radius: 4
        color: failed ? Theme.accentRed : on ? Theme.primary : Theme.alpha(Theme.textSecondary, 0.38)
    }
}
