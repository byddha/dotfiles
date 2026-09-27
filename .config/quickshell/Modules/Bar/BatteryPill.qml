import QtQuick
import "../../Config"
import "../../Components"

// Battery icon + percentage pill used for the system battery and peripheral batteries.
BarPill {
    id: root

    property string icon
    property int percentage
    property bool charging
    property bool isLow
    property bool isCritical
    property bool pulseWhileCharging: false
    property alias tooltipText: batteryTooltip.text

    width: visible ? batteryRow.implicitWidth + BarStyle.spacing * 2 : 0
    color: isCritical ? Theme.accentRed : BarStyle.buttonBackground
    highlightOnHover: !isCritical
    tooltip: batteryTooltip

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
        id: batteryRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.iconSize
            color: root.isCritical ? Theme.colLayer0 : (root.charging ? Theme.primary : (root.isLow ? Theme.accentOrange : Theme.primary))

            SequentialAnimation on opacity {
                running: root.pulseWhileCharging && root.charging
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
            text: `${root.percentage}%`
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: root.isCritical ? Theme.colLayer0 : BarStyle.textColor
        }
    }

    Tooltip {
        id: batteryTooltip
        target: root
    }
}
