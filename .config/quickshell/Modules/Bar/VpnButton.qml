import QtQuick
import "../../Config"
import "../../Services"
import "../../Components"

// A connected (or connecting) VPN; a click disconnects it
BarItem {
    id: root

    readonly property bool mullvad: Vpn.mullvadConnected || Vpn.mullvadBusy

    visible: Vpn.anyConnected || Vpn.busy
    iconOnly: !vertical && level >= 3

    function lengthAt(level) {
        if (vertical)
            return padded(Theme.iconSize + (level < 3 && !Vpn.busy ? BarLayout.itemGap + caption.implicitHeight : 0));
        if (level >= 3)
            return BarLayout.itemSize;
        const parts = [Theme.iconSize, level < 2 && !Vpn.busy ? name.implicitWidth : 0, detail.implicitWidth].filter(w => w > 0);
        return padded(parts.reduce((a, b) => a + b, 0) + BarLayout.itemGap * (parts.length - 1));
    }
    tooltipTitle: mullvad ? `Mullvad${Vpn.mullvadCity ? ` (${Vpn.mullvadCity})` : ""}` : "FortiVPN"
    tooltipDetail: {
        if (Vpn.busy)
            return Vpn.disconnecting ? "Disconnecting…" : "Connecting…";
        if (mullvad)
            return `${Vpn.mullvadCountry || "Connected"}\nClick to disconnect`;
        // The status is read every 5 s, so the seconds move in steps
        const s = Vpn.fortiUptimeSeconds;
        const clock = `${Math.floor(s / 3600)}:${String(Math.floor(s % 3600 / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
        return `Up ${clock}\nClick to disconnect`;
    }

    onClicked: mouse => {
        if (mouse.button !== Qt.LeftButton || Vpn.busy)
            return;
        if (Vpn.mullvadConnected)
            Vpn.disconnectMullvad();
        else if (Vpn.fortiConnected)
            Vpn.disconnectForti();
    }

    Item {
        implicitWidth: Theme.iconSize
        implicitHeight: Theme.iconSize

        Spinner {
            visible: Vpn.busy
            color: Theme.accentYellow
        }
        Icon {
            visible: !Vpn.busy
            text: Lucide.shieldCheck
            color: Theme.accentGreen
        }
    }
    StyledText {
        id: name

        visible: !root.vertical && !Vpn.busy && root.level < 2
        text: root.mullvad ? "Mullvad" : "FortiVPN"
    }
    StyledText {
        id: detail

        visible: !root.vertical && root.level < 3 && text !== ""
        role: !Vpn.busy && !root.mullvad ? "tertiary" : "secondary"
        text: Vpn.busy ? (Vpn.disconnecting ? "Disconnecting…" : "Connecting…") : root.mullvad ? (Vpn.mullvadCity ? `(${Vpn.mullvadCity})` : "") : Vpn.fortiUptime
    }
    StyledText {
        id: caption

        visible: root.vertical && !Vpn.busy && root.level < 3
        font.pixelSize: Theme.fontSizeTiny
        font.weight: Font.DemiBold
        text: "VPN"
    }
}
