pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components"

Scope {
    id: root

    readonly property int totalSeconds: 10
    property var lowDevices: []
    property int remaining: totalSeconds

    Connections {
        target: Settings
        function onShutdownReminderVisibleChanged() {
            if (!Settings.shutdownReminderVisible)
                return;
            root.lowDevices = PeripheralBatteries.getLowBatteryDevices();
            root.remaining = root.totalSeconds;
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
                color: Theme.hostSurface
                radius: Theme.radiusBase
                border.color: Theme.popupBorder
                border.width: 1

                ColumnLayout {
                    id: contentLayout
                    anchors.centerIn: parent
                    spacing: Theme.spacingBase

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `Shutting down in ${root.remaining}s`
                        font.pixelSize: Theme.fontSizeTitle
                        font.weight: Font.DemiBold
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        role: "secondary"
                        text: "Consider plugging in:"
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

                            Icon {
                                text: modelData?.icon ?? ""
                                color: parent.accent
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData?.label ?? "Device"
                            }

                            StyledText {
                                text: `${parent.percentage}%`
                                color: parent.accent
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }
        }
    }
}
