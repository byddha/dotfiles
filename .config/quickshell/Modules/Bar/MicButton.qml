import QtQuick
import "../../Config"
import "../../Utils"
import "../../Services"

Rectangle {
    id: micButton

    width: contentRow.implicitWidth + BarStyle.spacing * 2
    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

    property string micIcon: Audio.isMicMuted ? Icons.micMuted : Icons.micOn

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2
        height: parent.height

        Text {
            id: iconText
            text: micButton.micIcon
            font.family: BarStyle.iconFont
            font.pixelSize: Audio.isMicMuted ? BarStyle.iconSize : BarStyle.iconSize - 4
            color: Audio.isMicMuted ? BarStyle.iconColorMuted : Theme.primary
            height: parent.height
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: percentText
            text: Math.round(Audio.micVolume * 100) + "%"
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: Audio.isMicMuted ? BarStyle.textSecondaryColor : BarStyle.textColor
            height: parent.height
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                Settings.sidebarSelectedTab = 0
                Settings.sidebarVisible = true
            } else if (mouse.button === Qt.RightButton) {
                Audio.toggleMicMute();
            }
        }

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                Audio.increaseMicVolume();
            else
                Audio.decreaseMicVolume();
        }
    }

    states: State {
        name: "hovered"
        when: mouseArea.containsMouse
        PropertyChanges {
            target: micButton
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
