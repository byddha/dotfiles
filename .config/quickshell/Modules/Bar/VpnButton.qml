import QtQuick
import "../../Config"
import "../../Services"
import "../../Components"

BarPill {
    id: vpnButton

    readonly property bool isMullvad: Vpn.mullvadConnected || Vpn.mullvadBusy

    visible: Vpn.anyConnected || Vpn.busy
    width: visible ? vpnRow.implicitWidth + BarStyle.spacing * 2 : 0
    tooltip: vpnTooltip
    highlightOnHover: !Vpn.busy
    cursorShape: Vpn.busy ? Qt.BusyCursor : Qt.PointingHandCursor
    onClicked: {
        if (Vpn.busy)
            return;
        if (Vpn.mullvadConnected) {
            Vpn.disconnectMullvad();
        } else if (Vpn.fortiConnected) {
            Vpn.disconnectForti();
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        id: vpnRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2

        Text {
            visible: !Vpn.busy
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.vpnOn
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.iconSize
            color: Theme.primary
        }

        Spinner {
            visible: Vpn.busy
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: BarStyle.iconSize
            color: Theme.primary
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: vpnButton.isMullvad ? "Mullvad" : "FortiVPN"
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: BarStyle.textColor
        }

        Text {
            visible: Vpn.busy
            anchors.verticalCenter: parent.verticalCenter
            text: Vpn.disconnecting ? "Disconnecting…" : "Connecting…"
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            color: BarStyle.textSecondaryColor
        }

        Text {
            visible: !Vpn.busy && Vpn.mullvadConnected && Vpn.mullvadCity
            anchors.verticalCenter: parent.verticalCenter
            text: `(${Vpn.mullvadCity})`
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            color: BarStyle.textSecondaryColor
        }

        Text {
            visible: !Vpn.busy && Vpn.fortiConnected
            anchors.verticalCenter: parent.verticalCenter
            text: `(${Vpn.fortiUptime})`
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            color: BarStyle.textSecondaryColor
        }
    }

    Tooltip {
        id: vpnTooltip
        target: vpnButton
        text: Vpn.mullvadConnected ? `Mullvad VPN - ${Vpn.mullvadCity || ""}, ${Vpn.mullvadCountry || "Connected"}\nClick to disconnect` : `FortiVPN - Uptime ${Vpn.fortiUptime}\nClick to disconnect`
    }
}
