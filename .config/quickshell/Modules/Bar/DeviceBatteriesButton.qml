pragma ComponentBehavior: Bound
import QtQuick
import "../../Config"
import "../../Services"
import "../../Components"

// Every peripheral's battery in one item; the tooltip names them
BarItem {
    id: root

    readonly property var devices: PeripheralBatteries.devices

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
    readonly property bool collapsed: devices.length > 1 && level >= 1
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

    onClicked: mouse => {
        if (mouse.button !== Qt.LeftButton)
            return;
        Settings.toggleSidebarTab(4);
    }

    function lengthAt(level) {
        const collapsedThen = devices.length > 1 && level >= 1;
        const lengths = [];
        // repeater.count, not devices.length: the binding must also wait for the delegates
        for (let i = 0; i < repeater.count; i++) {
            const device = repeater.itemAt(i);
            if (!device || (collapsedThen && i !== lowest))
                continue;
            lengths.push(vertical ? Theme.iconSize + (level < 3 ? 4 + device.captionHeight : 0) : Theme.iconSize + 4 + device.captionWidth);
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

            Icon {
                text: PeripheralBatteries.getIconForType(device.modelData.type)
                color: device.modelData.charging ? Theme.accentGreen : device.tint
            }
            StyledText {
                id: caption

                visible: !root.vertical || root.level < 3
                font.pixelSize: root.vertical ? Theme.fontSizeTiny : Theme.fontSizeBase
                font.weight: root.vertical ? Font.DemiBold : Font.Medium
                color: device.modelData.charging ? Theme.textColor : device.tint
                text: device.modelData.percentage
            }
        }
    }

    StyledText {
        id: more

        visible: root.collapsed && (!root.vertical || root.level < 3)
        role: "secondary"
        font.pixelSize: Theme.fontSizeTiny
        text: `+${root.devices.length - 1}`
    }
}
