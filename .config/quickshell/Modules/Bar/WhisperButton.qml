import QtQuick
import "../../Config"
import "../../Services"

Rectangle {
    id: whisperButton

    visible: Whisper.recording
    width: visible ? whisperRow.implicitWidth + BarStyle.spacing * 2 : 0
    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

    property int elapsedSeconds: 0

    function formatTime(totalSeconds) {
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        return String(minutes).padStart(2, '0') + ":" + String(seconds).padStart(2, '0');
    }

    onVisibleChanged: {
        if (visible) {
            elapsedSeconds = 0;
            timer.start();
        } else {
            timer.stop();
            elapsedSeconds = 0;
        }
    }

    Timer {
        id: timer
        interval: 1000
        repeat: true
        onTriggered: whisperButton.elapsedSeconds++
    }

    Behavior on width {
        NumberAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        id: whisperRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.micOn
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.iconSize
            color: Theme.accentOrange
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Transcribing"
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: BarStyle.textColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: `(${whisperButton.formatTime(whisperButton.elapsedSeconds)})`
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            color: BarStyle.textSecondaryColor
        }
    }
}
