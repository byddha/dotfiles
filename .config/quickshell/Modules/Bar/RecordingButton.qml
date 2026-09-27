import QtQuick
import Quickshell
import "../../Config"
import "../../Services"

ActivityPill {
    visible: Recording.recording
    color: mouseArea.containsMouse ? BarStyle.buttonBackgroundHover : BarStyle.buttonBackground
    icon: Icons.recordOn
    iconColor: Theme.accentRed
    label: "Recording"

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // SIGINT lets wf-recorder finalize the file
        onClicked: Quickshell.execDetached(["pkill", "-INT", "wf-recorder"])
    }
}
