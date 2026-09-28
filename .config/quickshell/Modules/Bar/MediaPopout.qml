import QtQuick
import QtQuick.Effects
import Quickshell.Io
import "../../Config"
import "../../Components"

// The playing track with a visualizer, shown while the media item is hovered
BarAnchoredPopup {
    id: root

    property bool shown: false
    property list<real> visualizerValues: []

    visible: shown && delay.done
    implicitWidth: 280 + padLeft + padRight
    implicitHeight: 100 + padTop + padBottom

    Timer {
        id: delay

        property bool done: false

        interval: 400
        running: root.shown
        onRunningChanged: if (running)
            done = false
        onTriggered: done = true
    }

    Process {
        running: root.visible
        command: ["cava", "-p", Qt.resolvedUrl("../../scripts/cava_config.txt").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: data => root.visualizerValues = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p))
        }
    }

    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        blur: 24
        offset: Qt.vector2d(0, 8)
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    MediaCard {
        id: card

        x: root.padLeft
        y: root.padTop
        width: 280
        height: 100
        visualizerValues: root.visualizerValues
        radius: Theme.radiusWindow
        border.color: Theme.outlineVariant
        border.width: 1
    }
}
