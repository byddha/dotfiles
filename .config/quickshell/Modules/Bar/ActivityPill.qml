import QtQuick
import "../../Components"

// Icon + label + elapsed mm:ss pill for running activities (recording, transcribing).
// The timer restarts from zero each time the pill becomes visible.
// `busy`: the activity was told to stop (or is finishing) but has not ended yet; a spinner
// replaces the icon so a click never looks ignored.
Rectangle {
    id: root

    property string icon
    property color iconColor
    property string label
    property bool busy: false
    property int elapsedSeconds: 0

    function formatTime(totalSeconds) {
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        return String(minutes).padStart(2, '0') + ":" + String(seconds).padStart(2, '0');
    }

    width: visible ? activityRow.implicitWidth + BarStyle.spacing * 2 : 0
    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

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
        onTriggered: root.elapsedSeconds++
    }

    Behavior on width {
        NumberAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        id: activityRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2

        Text {
            visible: !root.busy
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.iconSize
            color: root.iconColor
        }

        Spinner {
            visible: root.busy
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: BarStyle.iconSize
            color: root.iconColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: BarStyle.textColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: `(${root.formatTime(root.elapsedSeconds)})`
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            color: BarStyle.textSecondaryColor
        }
    }
}
