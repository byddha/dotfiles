import QtQuick
import "../../Config"
import "../../Services"

// A connected (or connecting) VPN; a click disconnects it
BarItem {
    id: root

    readonly property bool mullvad: Vpn.mullvadConnected || Vpn.mullvadBusy

    visible: Vpn.anyConnected || Vpn.busy
    tooltipTitle: mullvad ? `Mullvad${Vpn.mullvadCity ? ` (${Vpn.mullvadCity})` : ""}` : "FortiVPN"
    tooltipDetail: Vpn.busy ? (Vpn.disconnecting ? "Disconnecting…" : "Connecting…") : mullvad ? `${Vpn.mullvadCountry || "Connected"}\nClick to disconnect` : `Up ${Vpn.fortiUptime}\nClick to disconnect`

    onClicked: mouse => {
        if (mouse.button !== Qt.LeftButton || Vpn.busy)
            return;
        if (Vpn.mullvadConnected)
            Vpn.disconnectMullvad();
        else if (Vpn.fortiConnected)
            Vpn.disconnectForti();
    }

    Item {
        implicitWidth: 16
        implicitHeight: 16

        BarSpinner {
            visible: Vpn.busy
            color: Theme.accentYellow
        }
        BarIcon {
            visible: !Vpn.busy
            text: Lucide.shieldCheck
            color: Theme.accentGreen
        }
    }
    BarText {
        visible: !root.vertical && !Vpn.busy
        text: root.mullvad ? "Mullvad" : "FortiVPN"
    }
    BarText {
        visible: !root.vertical
        role: "secondary"
        text: Vpn.busy ? (Vpn.disconnecting ? "Disconnecting…" : "Connecting…") : root.mullvad ? (Vpn.mullvadCity ? `(${Vpn.mullvadCity})` : "") : Vpn.fortiUptime
    }
    BarText {
        visible: root.vertical && !Vpn.busy
        font.pixelSize: 11
        font.weight: Font.DemiBold
        text: "VPN"
    }
}
