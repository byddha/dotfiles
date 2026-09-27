pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../Config"
import "../../../Components"
import "../../../Services"

ScrollList {
    id: root

    property bool shown: false

    function deviceIcon(node, isOutput) {
        if (!isOutput)
            return Icons.microphone;
        const name = (node?.name ?? "").toLowerCase();
        if (name.includes("hdmi") || name.includes("displayport"))
            return Icons.monitor;
        if (name.startsWith("bluez"))
            return Icons.headphones;
        return Icons.speaker;
    }

    SectionHeader {
        first: true
        text: "Apps"
        meta: Audio.groupedOutputAppNodes.length > 0 ? `${Audio.groupedOutputAppNodes.length} playing` : ""
    }

    Repeater {
        model: ScriptModel {
            values: Audio.groupedOutputAppNodes
        }

        VolumeMixerGroupEntry {
            required property var modelData
            Layout.fillWidth: true
            group: modelData
        }
    }

    EmptyState {
        Layout.fillWidth: true
        visible: Audio.groupedOutputAppNodes.length === 0
        text: "No apps playing audio"
        icon: Icons.volumeMuted
    }

    DeviceSection {
        title: "Output devices"
        devices: Audio.outputDevices
        selectedId: Audio.sink?.id
        isOutput: true
        onDeviceSelected: device => Audio.setDefaultSink(device)
    }

    DeviceSection {
        title: "Input devices"
        devices: Audio.inputDevices
        selectedId: Audio.source?.id
        isOutput: false
        onDeviceSelected: device => Audio.setDefaultSource(device)
    }

    component DeviceSection: ColumnLayout {
        id: section

        property string title
        property var devices
        property var selectedId
        property bool isOutput

        signal deviceSelected(var device)

        Layout.fillWidth: true
        spacing: 2

        SectionHeader {
            text: section.title
        }

        Repeater {
            model: ScriptModel {
                values: section.devices
            }

            ListRow {
                required property var modelData
                readonly property bool isCurrent: modelData.id === section.selectedId
                Layout.fillWidth: true
                leadIcon: root.deviceIcon(modelData, section.isOutput)
                title: Audio.friendlyDeviceName(modelData)
                selected: isCurrent
                trailIcon: isCurrent ? Icons.check : ""
                onClicked: {
                    if (!isCurrent)
                        section.deviceSelected(modelData);
                }
            }
        }
    }
}
