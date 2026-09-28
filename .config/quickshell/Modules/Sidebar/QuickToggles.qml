import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Components"
import "../../Services"

Card {
    id: root

    GridLayout {
        Layout.fillWidth: true
        columns: 5
        rowSpacing: 8
        columnSpacing: 8

        // Row 1: connectivity
        Tile {
            icon: Network.wifiEnabled ? Lucide.wifi : Lucide.wifiOff
            label: "Wi-Fi"
            active: Network.wifiEnabled
            onClicked: Network.toggleWifi()
        }
        Tile {
            icon: Bluetooth.enabled ? Lucide.bluetooth : Lucide.bluetoothOff
            label: "Bluetooth"
            active: Bluetooth.enabled
            onClicked: Bluetooth.toggleEnabled()
        }
        Tile {
            icon: Lucide.shieldLock
            label: "VPN"
            active: Vpn.anyConnected
            hasMenu: true
            menuOpen: vpnSelector.expanded
            onClicked: vpnSelector.expanded = !vpnSelector.expanded
        }
        Tile {
            icon: Lucide.plane
            label: "Airplane Mode"
            active: AirplaneMode.enabled
            onClicked: AirplaneMode.toggle()
        }
        Tile {
            icon: Lucide.bellOff
            label: "Do Not Disturb"
            active: Notifications.dnd
            onClicked: Notifications.toggleDnd()
        }

        // Row 2: display and tools
        Tile {
            icon: Lucide.hdr
            label: "HDR"
            active: Hdr.enabled
            onClicked: Hdr.toggle()
        }
        Tile {
            icon: Lucide.coffee
            label: "Idle Inhibitor"
            active: Idle.inhibit
            onClicked: Idle.toggleInhibit()
        }
        Tile {
            icon: Lucide.crop
            label: "Screen Snip"
        }
        Tile {
            icon: Lucide.pipette
            label: "Color Picker"
            onClicked: Actions.launchColorPicker()
        }
        Tile {
            icon: Lucide.circleDot
            label: "Recording"
            danger: true
        }
    }

    VpnSelector {
        id: vpnSelector
        Layout.fillWidth: true
    }

    component Tile: ToggleTile {
        Layout.fillWidth: true
        Layout.preferredHeight: width
    }
}
