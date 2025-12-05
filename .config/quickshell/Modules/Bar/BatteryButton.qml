import QtQuick
import "../../Config"
import "../../Services"
import "../../Components"

Rectangle {
    id: batteryButton

    visible: Battery.available
    width: visible ? batteryRow.implicitWidth + BarStyle.spacing * 2 : 0
    height: BarStyle.buttonSize
    color: Battery.isCritical ? Theme.accentRed : BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

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
            text: Battery.getIcon()
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.iconSize
            color: Battery.charging ? Theme.primary : (Battery.isLow ? Theme.accentOrange : Theme.primary)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: `${Battery.percentage}%`
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: Battery.isCritical ? Theme.colLayer0 : BarStyle.textColor
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
        target: batteryButton
        text: Battery.getStatusText()
    }

    states: State {
        name: "hovered"
        when: mouseArea.containsMouse && !Battery.isCritical
        PropertyChanges {
            target: batteryButton
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
