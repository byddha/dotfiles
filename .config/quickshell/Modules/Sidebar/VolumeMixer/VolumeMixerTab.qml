import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../Config"
import "../../../Components"
import "../../../Services"
import "../../../Utils"

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

            // List of apps playing audio
            Repeater {
                model: ScriptModel {
                    values: Audio.outputAppNodes
                }

                VolumeMixerEntry {
                    required property var modelData
                    Layout.fillWidth: true
                    node: modelData
                }
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: emptyText.height
                visible: Audio.outputAppNodes.length === 0

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

    // Output devices section
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        StyledText {
            text: "Output Devices"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textSecondary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: ScriptModel {
                    values: Audio.outputDevices
                }

                DeviceListItem {
                    required property var modelData
                    Layout.fillWidth: true

                    deviceName: Audio.friendlyDeviceName(modelData)
                    isSelected: modelData.id === Audio.sink?.id

                    onClicked: {
                        Audio.setDefaultSink(modelData)
                        Logger.info(`Switched to output device: ${deviceName}`)
                    }
                }
            }
        }
    }

    // Input devices section
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        StyledText {
            text: "Input Devices"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textSecondary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: ScriptModel {
                    values: Audio.inputDevices
                }

                DeviceListItem {
                    required property var modelData
                    Layout.fillWidth: true

                    deviceName: Audio.friendlyDeviceName(modelData)
                    isSelected: modelData.id === Audio.source?.id

                    onClicked: {
                        Audio.setDefaultSource(modelData)
                        Logger.info(`Switched to input device: ${deviceName}`)
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        Logger.info("Volume mixer tab loaded")
    }
}
