import QtQuick
import "../../Config"
import "../../Components"
import "../../Utils"
import "../../Services"

Card {
    id: root

    title: "Quick Toggles"
    collapsible: true
    collapsed: false

    Column {
        width: parent.width
        spacing: Theme.spacingBase

        Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 5
            spacing: Theme.spacingBase

            QuickToggleButton { icon: Icons.wifiOn; iconOff: Icons.wifiOff; label: "WiFi"; isStateful: true; isActive: Network.wifiEnabled; onClicked: Network.toggleWifi() }
            QuickToggleButton { icon: Icons.bluetoothOn; iconOff: Icons.bluetoothOff; label: "Bluetooth"; isStateful: true; isActive: Bluetooth.enabled; onClicked: Bluetooth.toggleEnabled() }
            QuickToggleButton { icon: Icons.vpnOn; iconOff: Icons.vpnOff; label: "VPN"; isStateful: true; isActive: Vpn.anyConnected; onClicked: vpnSelector.expanded = !vpnSelector.expanded }
            QuickToggleButton { icon: Icons.hdrOn; iconOff: Icons.hdrOff; label: "HDR"; isStateful: true; isActive: Hdr.enabled; onClicked: Hdr.toggle(); iconSize: 48 }
            QuickToggleButton { icon: Icons.bell; iconOff: Icons.bellOff; label: "Notifications"; isStateful: true; isActive: !Notifications.dnd; onClicked: Notifications.toggleDnd() }
            QuickToggleButton { icon: Icons.idleOff; iconOff: Icons.idleOn; label: "Idle Inhibitor"; isStateful: true; isActive: Idle.inhibit; onClicked: Idle.toggleInhibit() }
            QuickToggleButton { icon: Icons.screenSnip; label: "Screen Snip"; isStateful: false }
            QuickToggleButton { icon: Icons.colorPicker; label: "Color Picker"; isStateful: false; onClicked: Actions.launchColorPicker() }
            QuickToggleButton { icon: Icons.recordOn; iconOff: Icons.recordOff; label: "Recording"; isStateful: true; isActive: false }
            QuickToggleButton { icon: Icons.airplaneOn; iconOff: Icons.airplaneOff; label: "Airplane Mode"; isStateful: true; isActive: AirplaneMode.enabled; onClicked: AirplaneMode.toggle() }
        }

        VpnSelector {
            id: vpnSelector
            width: parent.width
        }
    }

    Component.onCompleted: {
        Logger.info("Panel loaded")
    }
}
