import QtQuick
import "../../Config"
import "../../Services"

ActivityPill {
    visible: Recording.recording || Recording.starting
    busy: Recording.starting || Recording.stopping
    color: mouseArea.containsMouse && !busy ? BarStyle.buttonBackgroundHover : BarStyle.buttonBackground
    icon: Icons.recordOn
    iconColor: Theme.accentRed
    label: Recording.stopping ? "Saving…" : Recording.starting ? "Starting…" : "Recording"

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: parent.busy ? Qt.BusyCursor : Qt.PointingHandCursor
        onClicked: Recording.stop()
    }
}
