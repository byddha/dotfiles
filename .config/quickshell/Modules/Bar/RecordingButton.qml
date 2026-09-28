import QtQuick
import "../../Config"
import "../../Services"
import "../../Components"

// While recording: the elapsed time; a click stops it. Starting and saving show a spinner.
BarItem {
    id: root

    readonly property bool busy: Recording.starting || Recording.stopping

    visible: Recording.recording || Recording.starting
    tooltipTitle: busy ? "" : "Recording"
    tooltipDetail: "Click to stop"

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton && !busy)
            Recording.stop();
    }

    Item {
        implicitWidth: Theme.iconSize
        implicitHeight: Theme.iconSize

        Spinner {
            visible: root.busy
            color: Theme.accentRed
        }
        // Hovered, the dot turns into a stop button
        Icon {
            visible: !root.busy && root.hovered
            text: Lucide.circleStop
            color: Theme.accentRed
        }
        Rectangle {
            visible: !root.busy && !root.hovered
            anchors.centerIn: parent
            width: 7
            height: 7
            radius: 3.5
            color: Theme.accentRed
            border.width: 3
            border.color: Theme.alpha(Theme.accentRed, 0.22)
        }
    }
    StyledText {
        visible: root.busy && !root.vertical
        role: "secondary"
        text: Recording.stopping ? "Saving…" : "Starting…"
    }
    ElapsedText {
        visible: !root.busy
        font.pixelSize: root.vertical ? Theme.fontSizeTiny : Theme.fontSizeBase
        font.weight: root.vertical ? Font.DemiBold : Font.Medium
        since: Recording.startedAt
    }
}
