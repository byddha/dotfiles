import QtQuick
import "../../Config"
import "../../Utils"
import "../../Services"

Rectangle {
    id: volumeButton

    width: contentRow.implicitWidth + BarStyle.spacing * 2
    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

    property string volumeIcon: {
        if (Audio.isMuted || Audio.volume === 0)
            return Icons.volumeMuted
        else if (Audio.volume > 0.66)
            return Icons.volumeHigh
        else if (Audio.volume > 0.33)
            return Icons.volumeMedium
        else
            return Icons.volumeLow
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2
        height: parent.height

        Text {
            id: iconText
            text: volumeButton.volumeIcon
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.iconSize
            color: Audio.isMuted ? BarStyle.iconColorMuted : Theme.primary
            height: parent.height
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: percentText
            text: Math.round(Audio.volume * 100) + "%"
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: Audio.isMuted ? BarStyle.textSecondaryColor : BarStyle.textColor
            height: parent.height
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Settings.sidebarSelectedTab = 0
                Settings.sidebarVisible = true
            } else if (mouse.button === Qt.RightButton) {
                Audio.toggleMute()
            }
        }

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0)
                Audio.increaseVolume()
            else
                Audio.decreaseVolume()
        }
    }

    states: State {
        name: "hovered"
        when: mouseArea.containsMouse
        PropertyChanges {
            target: volumeButton
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
