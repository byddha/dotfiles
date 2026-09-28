pragma ComponentBehavior: Bound
import QtQuick
import "../../Config"
import "../../Services"

// Every peripheral's battery in one item; the tooltip names them
BarItem {
    id: root

    readonly property var devices: PeripheralBatteries.devices

    function glyphFor(type) {
        switch (type) {
        case "mouse":
            return Lucide.mouse;
        case "keyboard":
            return Lucide.keyboard;
        case "trackpad":
            return Lucide.touchpad;
        case "headphones":
        case "headset":
            return Lucide.headphones;
        case "speakers":
            return Lucide.speaker;
        case "gamepad":
            return Lucide.gamepad2;
        case "phone":
            return Lucide.smartphone;
        default:
            return Lucide.batteryMedium;
        }
    }

    function colorFor(device) {
        if (device.charging)
            return Theme.accentGreen;
        if (device.percentage <= PeripheralBatteries.criticalThreshold)
            return Theme.accentRed;
        if (device.percentage <= PeripheralBatteries.lowThreshold)
            return Theme.accentOrange;
        return Theme.textColor;
    }

    visible: devices.length > 0
    spacing: vertical ? 8 : 10
    tooltipTitle: "Device batteries"
    tooltipDetail: devices.map(d => `${d.name} · ${d.percentage}%` + (d.charging ? " · charging" : d.percentage <= PeripheralBatteries.lowThreshold ? " · low" : "")).join("\n")

    Repeater {
        model: root.devices

        Grid {
            id: device

            required property var modelData
            readonly property color tint: root.colorFor(modelData)

            columns: root.vertical ? 1 : 2
            spacing: 4
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            BarIcon {
                text: root.glyphFor(device.modelData.type)
                color: device.modelData.charging ? Theme.accentGreen : device.tint
            }
            BarText {
                font.pixelSize: root.vertical ? 11 : 13
                font.weight: root.vertical ? Font.DemiBold : Font.Medium
                color: device.modelData.charging ? Theme.textColor : device.tint
                text: device.modelData.percentage
            }
        }
    }
}
