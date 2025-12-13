pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../../Config"
import "../../../Components"

PopupWindow {
    id: root

    property MprisPlayer activePlayer
    property var anchorItem: null
    property list<real> visualizerValues: []

    implicitWidth: 280
    implicitHeight: 100
    visible: true
    color: "transparent"

    // CAVA process for audio visualization
    Process {
        id: cavaProc
        running: root.visible
        command: ["cava", "-p", Qt.resolvedUrl("../../../scripts/cava_config.txt").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: data => {
                root.visualizerValues = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
            }
        }
    }

    anchor.item: anchorItem
    anchor.rect.x: anchorItem ? (anchorItem.width / 2) - (implicitWidth / 2) : 0
    anchor.rect.y: anchorItem ? anchorItem.height + 4 : 0  // Below anchor with gap

    Component.onCompleted: {
        Qt.callLater(() => root.anchor.updateAnchor());
    }

    Item {
        anchors.fill: parent

        MediaCard {
            id: mediaCard
            anchors.fill: parent
            player: root.activePlayer
            showControls: false
            showVisualizer: true
            visualizerValues: root.visualizerValues
            border.color: Theme.colLayer0Border
            border.width: 1
        }
    }
}
