import QtQuick
import Quickshell.Services.UPower
import "../../Config"
import "../../Services"
import "../../Components"

Item {
    id: root

    visible: {
        for (let i = 0; i < peripheralRow.children.length; i++) {
            if (peripheralRow.children[i].visible)
                return true;
        }
        return false;
    }
    implicitWidth: peripheralRow.implicitWidth
    height: BarStyle.buttonSize

    Row {
        id: peripheralRow
        spacing: BarStyle.spacing
        height: parent.height

        // UPower peripherals (filtered — excludes replaced devices)
        Repeater {
            model: UPower.devices

            delegate: Rectangle {
                id: upowerButton
                required property var modelData

                property var _configDevices: Config.options.peripheralBatteries?.devices ?? []
                visible: PeripheralBatteries.isPeripheral(modelData, _configDevices)
                width: visible ? upowerRow.implicitWidth + BarStyle.spacing * 2 : 0
                height: BarStyle.buttonSize
                radius: BarStyle.buttonRadius

                property int percentage: Math.round((modelData?.percentage ?? 0) * 100)
                property bool charging: modelData?.state === UPowerDeviceState.Charging
                property bool isLow: !charging && percentage <= PeripheralBatteries.lowThreshold
                property bool isCritical: !charging && percentage <= PeripheralBatteries.criticalThreshold

                color: isCritical ? Theme.accentRed : BarStyle.buttonBackground

                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }

                Row {
                    id: upowerRow
                    anchors.centerIn: parent
                    spacing: BarStyle.spacing / 2

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: PeripheralBatteries.getDeviceIcon(modelData)
                        font.family: BarStyle.iconFont
                        font.pixelSize: BarStyle.iconSize
                        color: upowerButton.isCritical ? Theme.colLayer0 : (upowerButton.charging ? Theme.primary : (upowerButton.isLow ? Theme.accentOrange : Theme.primary))

                        SequentialAnimation on opacity {
                            running: upowerButton.charging
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 0.4
                                duration: 1000
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 1.0
                                duration: 1000
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${upowerButton.percentage}%`
                        font.family: BarStyle.textFont
                        font.pixelSize: BarStyle.textSize
                        font.weight: BarStyle.textWeight
                        color: upowerButton.isCritical ? Theme.colLayer0 : BarStyle.textColor
                    }
                }

                MouseArea {
                    id: upowerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: upowerTooltip.show()
                    onExited: upowerTooltip.hide()
                }

                Tooltip {
                    id: upowerTooltip
                    target: upowerButton
                    text: PeripheralBatteries.getDeviceStatusText(modelData)
                }

                states: State {
                    name: "hovered"
                    when: upowerMouse.containsMouse && !upowerButton.isCritical
                    PropertyChanges {
                        target: upowerButton
                        color: BarStyle.buttonBackgroundHover
                    }
                }

                transitions: Transition {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }

        // Custom devices from config
        Repeater {
            model: PeripheralBatteries.customDevices

            delegate: Rectangle {
                id: customButton
                required property var modelData

                visible: modelData?.present ?? false
                width: visible ? customRow.implicitWidth + BarStyle.spacing * 2 : 0
                height: BarStyle.buttonSize
                radius: BarStyle.buttonRadius

                property int percentage: modelData?.percentage ?? 0
                property bool charging: modelData?.charging ?? false
                property bool isLow: !charging && percentage <= PeripheralBatteries.lowThreshold
                property bool isCritical: !charging && percentage <= PeripheralBatteries.criticalThreshold

                color: isCritical ? Theme.accentRed : BarStyle.buttonBackground

                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }

                Row {
                    id: customRow
                    anchors.centerIn: parent
                    spacing: BarStyle.spacing / 2

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: customButton.modelData?.icon ?? ""
                        font.family: BarStyle.iconFont
                        font.pixelSize: BarStyle.iconSize
                        color: customButton.isCritical ? Theme.colLayer0 : (customButton.charging ? Theme.primary : (customButton.isLow ? Theme.accentOrange : Theme.primary))

                        SequentialAnimation on opacity {
                            running: customButton.charging
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 0.4
                                duration: 1000
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 1.0
                                duration: 1000
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${customButton.percentage}%`
                        font.family: BarStyle.textFont
                        font.pixelSize: BarStyle.textSize
                        font.weight: BarStyle.textWeight
                        color: customButton.isCritical ? Theme.colLayer0 : BarStyle.textColor
                    }
                }

                MouseArea {
                    id: customMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: customTooltip.show()
                    onExited: customTooltip.hide()
                }

                Tooltip {
                    id: customTooltip
                    target: customButton
                    text: {
                        const name = modelData?.name ?? "Device";
                        const pct = modelData?.percentage ?? 0;
                        const ch = modelData?.charging ?? false;
                        return `${name}: ${pct}%${ch ? " - Charging" : ""}`;
                    }
                }

                states: State {
                    name: "hovered"
                    when: customMouse.containsMouse && !customButton.isCritical
                    PropertyChanges {
                        target: customButton
                        color: BarStyle.buttonBackgroundHover
                    }
                }

                transitions: Transition {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }
}
