import QtQuick
import "../../Config"
import "../../Services"

Rectangle {
    id: recordingButton

    visible: Recording.recording
    width: visible ? recordingRow.implicitWidth + BarStyle.spacing * 2 : 0
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
        onTriggered: recordingButton.elapsedSeconds++
    }

    Behavior on width {
        NumberAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        id: recordingRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.recordOn
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.iconSize
            color: Theme.accentRed
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Recording"
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: BarStyle.textColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: `(${recordingButton.formatTime(recordingButton.elapsedSeconds)})`
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            color: BarStyle.textSecondaryColor
        }
    }
}
