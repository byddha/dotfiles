import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../Config"

// A card with a title, an optional keyboard shortcut and detail lines, shown after a short hover
BarAnchoredPopup {
    id: root

    property bool shown: false
    property string title: ""
    property string keys: ""
    property string detail: ""

    visible: shown && title !== "" && delay.done
    implicitWidth: card.implicitWidth + padLeft + padRight
    implicitHeight: card.implicitHeight + padTop + padBottom

    Timer {
        id: delay

        property bool done: false

        interval: 400
        running: root.shown
        onRunningChanged: if (running)
            done = false
        onTriggered: done = true
    }

    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        blur: 24
        offset: Qt.vector2d(0, 8)
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    Rectangle {
        id: card

        x: root.padLeft
        y: root.padTop
        implicitWidth: lines.implicitWidth + 24
        implicitHeight: lines.implicitHeight + 20
        radius: 8
        color: Theme.colLayer2
        border.width: 1
        border.color: Theme.colLayer3

        ColumnLayout {
            id: lines

            x: 12
            y: 10
            spacing: 2

            RowLayout {
                spacing: 8

                BarText {
                    text: root.title
                    font.pixelSize: BarLayout.tooltipTitleSize
                    font.weight: Font.DemiBold
                }
                BarKeycap {
                    visible: root.keys !== ""
                    text: root.keys
                }
            }

            BarText {
                visible: root.detail !== ""
                role: "secondary"
                text: root.detail
                font.pixelSize: BarLayout.tooltipTextSize
                lineHeight: 1.35
            }
        }
    }
}
