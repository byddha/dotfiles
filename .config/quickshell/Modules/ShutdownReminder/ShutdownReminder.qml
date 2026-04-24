pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Utils"

Scope {
    id: root

    readonly property int totalSeconds: 5
    property var lowDevices: []
    property int remaining: totalSeconds

    Connections {
        target: Settings
        function onShutdownReminderVisibleChanged() {
            if (!Settings.shutdownReminderVisible)
                return;
            const threshold = Config.options.peripheralBatteries?.shutdownReminderThreshold ?? 40;
            root.lowDevices = PeripheralBatteries.getLowBatteryDevices(threshold);
            root.remaining = root.totalSeconds;
            Logger.info(`Shutdown reminder shown, ${root.lowDevices.length} low device(s), poweroff in ${root.totalSeconds}s`);
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: Settings.shutdownReminderVisible
        onTriggered: {
            root.remaining -= 1;
            if (root.remaining <= 0) {
                Settings.shutdownReminderVisible = false;
                PowerActions.poweroff();
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: reminderWindow
            required property var modelData
            property bool monitorIsFocused: Compositor.focusedMonitorName === modelData.name

            screen: modelData
            visible: Settings.shutdownReminderVisible && monitorIsFocused
            color: Qt.rgba(0, 0, 0, 0.45)

            WlrLayershell.namespace: "bidshell:shutdown-reminder"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                implicitWidth: contentLayout.implicitWidth + Theme.spacingLarge * 2
                implicitHeight: contentLayout.implicitHeight + Theme.spacingLarge * 2
                color: Theme.colLayer0
                radius: Theme.radiusBase
                border.color: Theme.colLayer0Border
                border.width: 1

                ColumnLayout {
                    id: contentLayout
                    anchors.centerIn: parent
                    spacing: Theme.spacingBase

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: `Shutting down in ${root.remaining}s`
                        color: Theme.textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBase + 4
                        font.weight: Font.Black
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Consider plugging in:"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBase
                    }

                    Repeater {
                        model: root.lowDevices

                        delegate: RowLayout {
                            required property var modelData
                            Layout.alignment: Qt.AlignLeft
                            spacing: Theme.spacingBase

                            property int percentage: modelData?.percentage ?? 0
                            property bool isCritical: percentage <= PeripheralBatteries.criticalThreshold
                            property bool isLow: !isCritical && percentage <= PeripheralBatteries.lowThreshold
                            property color accent: isCritical ? Theme.accentRed : (isLow ? Theme.accentOrange : Theme.primary)

                            Text {
                                text: modelData?.icon ?? ""
                                color: parent.accent
                                font.family: Theme.fontFamilyIcons
                                font.pixelSize: Theme.fontSizeBase + 2
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData?.label ?? "Device"
                                color: Theme.textColor
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeBase
                            }

                            Text {
                                text: `${parent.percentage}%`
                                color: parent.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeBase
                                font.weight: Font.Black
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        Logger.info("ShutdownReminder initialized");
    }
}
