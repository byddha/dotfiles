import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import "../../Config"
import "../../Components"

// A card with a title, an optional keyboard shortcut and detail lines, and an optional image (the media
// cover), shown after a short hover. The image is always shown whole: a wide one sits above the text,
// any other next to it at full card height.
BarAnchoredPopup {
    id: root

    property bool shown: false
    property string title: ""
    property string keys: ""
    property string detail: ""
    property string image: ""
    // The shape to show the image at, 0 for its own; a wider image is cut to its centre
    property real imageAspect: 0
    // Shown in the image's place while there is none, so a card that has one keeps its shape
    property string fallbackIcon: ""

    readonly property bool hasImage: image !== "" && cover.status === Image.Ready
    readonly property bool hasCover: hasImage || fallbackIcon !== ""
    readonly property real aspect: !hasImage ? 1 : imageAspect > 0 ? imageAspect : cover.implicitWidth / cover.implicitHeight
    readonly property bool wide: hasImage && aspect >= 1.2
    readonly property int coverHeight: 246
    readonly property int textWidth: 240
    // Above the text, a wide image keeps two title lines and the detail lines in the card's height
    readonly property int wideWidth: 288
    readonly property int wideHeight: 162

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

        // The cover's card leaves 12 inside the border
        readonly property int pad: root.hasCover ? 13 : 12

        x: root.padLeft
        y: root.padTop
        implicitWidth: content.implicitWidth + 2 * pad
        implicitHeight: content.implicitHeight + (root.hasCover ? 2 * pad : 20)
        radius: 8
        color: Theme.chipSurface
        border.width: 1
        border.color: Theme.chipSurfaceNested

        GridLayout {
            id: content

            x: card.pad
            y: root.hasCover ? card.pad : 10
            columns: root.wide ? 1 : 2
            rowSpacing: 10
            columnSpacing: 12

            ClippingRectangle {
                id: coverBox

                visible: root.hasCover
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: root.wide ? Math.min(root.wideWidth, Math.round(root.wideHeight * root.aspect)) : Math.round(root.coverHeight * root.aspect)
                Layout.preferredHeight: root.wide ? Math.round(Layout.preferredWidth / root.aspect) : root.coverHeight
                radius: Theme.radiusBase
                color: Theme.chipSurfaceNested

                // The box has the image's own shape, so cropping only cuts what imageAspect asks for
                Image {
                    id: cover

                    anchors.fill: parent
                    visible: root.hasImage
                    source: root.image
                    sourceSize.height: 2 * root.coverHeight
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Icon {
                    anchors.centerIn: parent
                    visible: !root.hasImage
                    size: 56
                    text: root.fallbackIcon
                    color: Theme.textSecondary
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                spacing: 2

                RowLayout {
                    spacing: 8

                    StyledText {
                        // Long titles (media) wrap beside or under the cover instead of stretching the card
                        Layout.maximumWidth: !root.hasCover ? -1 : root.wide ? coverBox.Layout.preferredWidth : root.textWidth
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
                    Layout.maximumWidth: !root.hasCover ? -1 : root.wide ? coverBox.Layout.preferredWidth : root.textWidth
                    role: "secondary"
                    text: root.detail
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeSmall
                    lineHeight: 1.35
                }
            }
        }
    }
}
