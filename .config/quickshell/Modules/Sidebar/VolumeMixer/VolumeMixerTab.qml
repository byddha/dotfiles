pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../Config"
import "../../../Components"
import "../../../Services"

ColumnLayout {
    id: root

    spacing: Theme.spacingBase

    // App list
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 100

        clip: true

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: parent.width
            spacing: Theme.spacingBase

            // List of apps playing audio (grouped by application)
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

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: emptyText.height
                visible: Audio.groupedOutputAppNodes.length === 0

                StyledText {
                    id: emptyText
                    text: "No apps playing audio"
                    font.pixelSize: Theme.fontSizeBase
                    color: Theme.textSecondary
                    anchors.centerIn: parent
                }
            }
        }
    }

    DeviceSection {
        title: "Output Devices"
        devices: Audio.outputDevices
        selectedId: Audio.sink?.id
        onDeviceSelected: device => Audio.setDefaultSink(device)
    }

    DeviceSection {
        title: "Input Devices"
        devices: Audio.inputDevices
        selectedId: Audio.source?.id
        onDeviceSelected: device => Audio.setDefaultSource(device)
    }

    component DeviceSection: ColumnLayout {
        id: section

        property string title
        property var devices
        property var selectedId

        signal deviceSelected(var device)

        Layout.fillWidth: true
        spacing: 4

        StyledText {
            text: section.title
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textSecondary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: ScriptModel {
                    values: section.devices
                }

                DeviceListItem {
                    required property var modelData
                    Layout.fillWidth: true

                    deviceName: Audio.friendlyDeviceName(modelData)
                    isSelected: modelData.id === section.selectedId

                    onClicked: section.deviceSelected(modelData)
                }
            }
        }
    }
}
