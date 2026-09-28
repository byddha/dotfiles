import QtQuick
import "../../Config"
import "../../Services"

// A connected (or connecting) VPN; a click disconnects it
BarItem {
    id: root

    readonly property bool mullvad: Vpn.mullvadConnected || Vpn.mullvadBusy

    visible: Vpn.anyConnected || Vpn.busy
    iconOnly: !vertical && level >= 3

    function lengthAt(level) {
        if (vertical)
            return padded(16 + (level < 3 && !Vpn.busy ? 4 + caption.implicitHeight : 0));
        if (level >= 3)
            return BarLayout.itemSize;
        const parts = [16, level < 2 && !Vpn.busy ? name.implicitWidth : 0, detail.implicitWidth].filter(w => w > 0);
        return padded(parts.reduce((a, b) => a + b, 0) + 6 * (parts.length - 1));
    }
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
        id: name

        visible: !root.vertical && !Vpn.busy && root.level < 2
        text: root.mullvad ? "Mullvad" : "FortiVPN"
    }
    BarText {
        id: detail

        visible: !root.vertical && root.level < 3 && text !== ""
        role: "secondary"
        text: Vpn.busy ? (Vpn.disconnecting ? "Disconnecting…" : "Connecting…") : root.mullvad ? (Vpn.mullvadCity ? `(${Vpn.mullvadCity})` : "") : Vpn.fortiUptime
    }
    BarText {
        id: caption

        visible: root.vertical && !Vpn.busy && root.level < 3
        font.pixelSize: 11
        font.weight: Font.DemiBold
        text: "VPN"
    }
}
