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

    // Collapsed: only the device with the lowest battery, and how many more there are
    readonly property bool collapsed: devices.length > 1 && level >= (vertical ? 2 : 1)
    readonly property int lowest: {
        let index = 0;
        for (let i = 1; i < devices.length; i++)
            if (devices[i].percentage < devices[index].percentage)
                index = i;
        return index;
    }

    visible: devices.length > 0
    spacing: vertical ? 8 : 10
    tooltipTitle: "Device batteries"
    tooltipDetail: devices.map(d => `${d.name} · ${d.percentage}%` + (d.charging ? " · charging" : d.percentage <= PeripheralBatteries.lowThreshold ? " · low" : "")).join("\n")

    function lengthAt(level) {
        const collapsedThen = devices.length > 1 && level >= (vertical ? 2 : 1);
        const lengths = [];
        // repeater.count, not devices.length: the binding must also wait for the delegates
        for (let i = 0; i < repeater.count; i++) {
            const device = repeater.itemAt(i);
            if (!device || (collapsedThen && i !== lowest))
                continue;
            lengths.push(vertical ? 16 + (level < 3 ? 4 + device.captionHeight : 0) : 16 + 4 + device.captionWidth);
        }
        if (collapsedThen)
            lengths.push(vertical ? (level < 3 ? more.implicitHeight : 0) : more.implicitWidth);
        const content = lengths.filter(l => l > 0);
        return padded(content.reduce((a, b) => a + b, 0) + spacing * Math.max(0, content.length - 1));
    }

    Repeater {
        id: repeater

        model: root.devices

        Grid {
            id: device

            required property var modelData
            required property int index
            readonly property color tint: root.colorFor(modelData)
            readonly property real captionWidth: caption.implicitWidth
            readonly property real captionHeight: caption.implicitHeight

            visible: !root.collapsed || index === root.lowest
            columns: root.vertical ? 1 : 2
            spacing: 4
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            BarIcon {
                text: root.glyphFor(device.modelData.type)
                color: device.modelData.charging ? Theme.accentGreen : device.tint
            }
            BarText {
                id: caption

                visible: !root.vertical || root.level < 3
                font.pixelSize: root.vertical ? 11 : 13
                font.weight: root.vertical ? Font.DemiBold : Font.Medium
                color: device.modelData.charging ? Theme.textColor : device.tint
                text: device.modelData.percentage
            }
        }
    }

    BarText {
        id: more

        visible: root.collapsed && (!root.vertical || root.level < 3)
        role: "secondary"
        font.pixelSize: 11
        text: `+${root.devices.length - 1}`
    }
}
