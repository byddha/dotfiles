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

        Repeater {
            model: UPower.devices

            delegate: Rectangle {
                id: deviceButton
                required property var modelData

                visible: PeripheralBatteries.isPeripheral(modelData)
                width: visible ? deviceRow.implicitWidth + BarStyle.spacing * 2 : 0
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
                    id: deviceRow
                    anchors.centerIn: parent
                    spacing: BarStyle.spacing / 2

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: PeripheralBatteries.getDeviceIcon(modelData)
                        font.family: BarStyle.iconFont
                        font.pixelSize: BarStyle.iconSize
                        color: deviceButton.isCritical ? Theme.colLayer0 : (deviceButton.charging ? Theme.primary : (deviceButton.isLow ? Theme.accentOrange : Theme.primary))
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${deviceButton.percentage}%`
                        font.family: BarStyle.textFont
                        font.pixelSize: BarStyle.textSize
                        font.weight: BarStyle.textWeight
                        color: deviceButton.isCritical ? Theme.colLayer0 : BarStyle.textColor
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: tooltip.show()
                    onExited: tooltip.hide()
                }

                Tooltip {
                    id: tooltip
                    target: deviceButton
                    text: PeripheralBatteries.getDeviceStatusText(modelData)
                }

                states: State {
                    name: "hovered"
                    when: mouseArea.containsMouse && !deviceButton.isCritical
                    PropertyChanges {
                        target: deviceButton
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
