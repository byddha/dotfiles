import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../Config"
import "../../../Components"
import "../../../Services"

ScrollList {
    id: root

    property bool shown: false

    // Tabs stay loaded, so read the batteries again each time this tab is shown
    onShownChanged: {
        if (shown)
            PeripheralBatteries.repollRequested();
    }
    Component.onCompleted: {
        if (shown)
            PeripheralBatteries.repollRequested();
    }

    SectionHeader {
        first: true
        text: "Batteries"
        meta: Peripherals.devices.length > 0 ? `${Peripherals.devices.length} device${Peripherals.devices.length === 1 ? "" : "s"}` : ""
    }

    Repeater {
        model: ScriptModel {
            values: Peripherals.devices
        }

        PeripheralDeviceItem {
            required property var modelData
            Layout.fillWidth: true
            device: modelData
        }
    }

    EmptyState {
        Layout.fillWidth: true
        visible: Peripherals.devices.length === 0
        text: "No battery devices"
        icon: Icons.device
    }
}
