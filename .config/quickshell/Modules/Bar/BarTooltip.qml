import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import "../../Config"
import "../../Components"

// A card with a title, an optional keyboard shortcut and detail lines, and an optional image on its
// left (the media cover), shown after a short hover
BarAnchoredPopup {
    id: root

    property bool shown: false
    property string title: ""
    property string keys: ""
    property string detail: ""
    property string image: ""

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
        implicitWidth: content.implicitWidth + 24
        implicitHeight: content.implicitHeight + 20
        radius: 8
        color: Theme.chipSurface
        border.width: 1
        border.color: Theme.chipSurfaceNested

        RowLayout {
            id: content

            x: 12
            y: 10
            spacing: 12

            ClippingRectangle {
                visible: root.image !== "" && cover.status === Image.Ready
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                radius: Theme.radiusBase
                color: "transparent"

                Image {
                    id: cover

                    anchors.fill: parent
                    source: root.image
                    sourceSize.width: 192
                    sourceSize.height: 192
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            ColumnLayout {
                spacing: 2

                RowLayout {
                    spacing: 8

                    StyledText {
                        // Long titles (media) wrap next to the image instead of stretching the card
                        Layout.maximumWidth: root.image !== "" ? 280 : -1
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        text: root.title
                        font.pixelSize: Theme.fontSizeBase
                        font.weight: Font.DemiBold
                    }
                    Keycap {
                        visible: root.keys !== ""
                        text: root.keys
                    }
                }

                StyledText {
                    visible: root.detail !== ""
                    role: "secondary"
                    text: root.detail
                    font.pixelSize: Theme.fontSizeSmall
                    lineHeight: 1.35
                }
            }
        }
    }
}
