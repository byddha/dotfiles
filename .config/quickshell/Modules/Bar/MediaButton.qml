pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import "../../Config"
import "../../Services"
import "../../Components"

/**
 * MediaButton - The playing track: round art in a progress ring, the title and the artist. Hover
 * turns the second line into the time and brings in previous / play-pause / next, widening the item
 * toward the bar's end; its tooltip shows the cover, the whole title and the track's length. The
 * wheel switches between players. On a vertical bar, and at level 3, only the ring (and on a
 * vertical bar the time) shows until hovered. Level 1 shortens the title.
 */
BarItem {
    id: root

    readonly property bool ringOnly: vertical || level >= 3
    readonly property int titleCap: level >= 1 ? 190 : 260
    readonly property int ringSize: vertical ? 36 : 32
    readonly property int ringStroke: 3
    // Light enough that what is left of the track reads at a glance
    readonly property color ringTrack: Theme.alpha(Theme.textSecondary, 0.3)
    // The controls' slot starts 6 past the item's spacing, so the text and the buttons sit 16 apart
    readonly property int slotLead: vertical ? 0 : 6
    // Three 28 px buttons, 2 apart
    readonly property int controlsLength: 3 * 28 + 2 * 2

    function formatTime(seconds) {
        const s = Math.floor(seconds);
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // Horizontally the hovered length at every level, so widening never runs into the neighbours.
    // Vertically only the ring and the time: the bar is short there, and the controls grow over the
    // gap after the start section while hovered. Only text and fixed sizes: positioners report 0
    // while hidden, which would tie the length to the hover.
    function lengthAt(level) {
        if (vertical)
            return padded(ringSize + spacing + verticalTime.implicitHeight);
        const textWidth = Math.max(title.implicitWidth, artist.implicitWidth, position.implicitWidth + duration.implicitWidth);
        const text = level >= 3 ? 0 : spacing + Math.min(textWidth, level >= 1 ? 190 : 260);
        return padded(ringSize + text + spacing + slotLead + controlsLength);
    }

    visible: Media.hasTrack
    spacing: vertical ? 4 : 10
    tooltipTitle: Media.title
    tooltipDetail: [Media.artist, Media.length > 0 ? formatTime(Media.length) : ""].filter(line => line).join("\n")
    tooltipImage: Media.artUrl

    onWheel: wheel => {
        if (wheel.angleDelta.y > 0)
            Media.cycle(-1);
        else if (wheel.angleDelta.y < 0)
            Media.cycle(1);
    }

    // Always there on a vertical bar, above the ring, so it never moves on hover.
    // Its room is kept even when the player gives no length, so the item never jumps; then it is
    // empty, or a dash while hovered.
    StyledText {
        id: verticalTime

        readonly property bool known: Media.length > 0

        visible: root.vertical
        opacity: known || root.hovered ? 1 : 0
        role: known ? "secondary" : "tertiary"
        font.pixelSize: BarLayout.badgeTextSize
        font.weight: Font.Medium
        text: known ? root.formatTime(Media.position) : "–:––"
    }

    Item {
        implicitWidth: root.ringSize
        implicitHeight: root.ringSize

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: root.ringTrack
                strokeWidth: root.ringStroke
                fillColor: "transparent"

                PathAngleArc {
                    centerX: root.ringSize / 2
                    centerY: root.ringSize / 2
                    radiusX: (root.ringSize - root.ringStroke) / 2
                    radiusY: (root.ringSize - root.ringStroke) / 2
                    sweepAngle: 360
                }
            }
            ShapePath {
                strokeColor: Theme.primary
                strokeWidth: root.ringStroke
                fillColor: "transparent"

                PathAngleArc {
                    centerX: root.ringSize / 2
                    centerY: root.ringSize / 2
                    radiusX: (root.ringSize - root.ringStroke) / 2
                    radiusY: (root.ringSize - root.ringStroke) / 2
                    startAngle: -90
                    // No arc when the player gives no length
                    sweepAngle: Media.length > 0 ? 360 * Math.min(1, Media.position / Media.length) : 0
                }
            }
        }

        ClippingRectangle {
            anchors.centerIn: parent
            // The art keeps a 2 px gap inside the ring
            width: root.ringSize - 2 * root.ringStroke - 4
            height: width
            radius: width / 2
            color: Theme.chipSurface

            Image {
                id: art

                anchors.fill: parent
                source: Media.artUrl
                sourceSize.width: parent.width * 2
                sourceSize.height: parent.height * 2
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: Media.playing ? 1 : 0.5
                visible: status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                size: Theme.iconSizeSmall
                text: Media.playing ? Lucide.music : Lucide.pause
                color: Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
            }
        }

        Icon {
            anchors.centerIn: parent
            visible: !Media.playing && art.status === Image.Ready
            size: 12
            text: Lucide.pause
        }
    }

    Column {
        visible: !root.ringOnly
        spacing: 2

        StyledText {
            id: title

            width: Math.min(implicitWidth, root.titleCap)
            height: 16
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeSmall
            text: Media.title
        }

        Item {
            width: Math.min(Math.max(artist.implicitWidth, time.visible ? time.implicitWidth : 0), root.titleCap)
            height: 14

            StyledText {
                id: artist

                width: Math.min(implicitWidth, root.titleCap)
                height: parent.height
                visible: !time.visible
                elide: Text.ElideRight
                role: "tertiary"
                font.pixelSize: Theme.fontSizeTiny
                text: Media.artist
            }

            Row {
                id: time

                // Without a length the position means little, so the artist stays
                visible: root.hovered && Media.length > 0
                height: parent.height

                StyledText {
                    id: position

                    height: parent.height
                    role: "secondary"
                    font.pixelSize: Theme.fontSizeTiny
                    font.weight: Font.Medium
                    text: root.formatTime(Media.position)
                }
                StyledText {
                    id: duration

                    height: parent.height
                    role: "tertiary"
                    font.pixelSize: Theme.fontSizeTiny
                    text: ` / ${root.formatTime(Media.length)}`
                }
            }
        }
    }

    // Revealed on hover at the far end: the item grows toward the bar's end, so the ring and the
    // title stay under the pointer and a click meant for them never lands on a button
    Item {
        implicitWidth: root.vertical ? 28 : (root.hovered ? root.slotLead + root.controlsLength : 0)
        implicitHeight: root.vertical ? (root.hovered ? root.controlsLength : 0) : 28
        visible: implicitWidth > 0.5 && implicitHeight > 0.5
        clip: true

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitHeight {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Grid {
            id: hoverParts

            // The slot's lead is the gap before the buttons
            anchors.right: parent.right
            anchors.top: parent.top
            columns: root.vertical ? 1 : 4
            spacing: 2
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            Control {
                glyph: Lucide.skipBack
                glyphSize: 16
                enabled: Media.canPrevious
                onTapped: Media.previous()
            }
            Control {
                glyph: Media.playing ? Lucide.pause : Lucide.play
                glyphSize: 20
                onTapped: Media.togglePlaying()
            }
            Control {
                glyph: Lucide.skipForward
                glyphSize: 16
                enabled: Media.canNext
                onTapped: Media.next()
            }
        }
    }

    component Control: Rectangle {
        id: control

        property string glyph
        property int glyphSize

        signal tapped

        implicitWidth: 28
        implicitHeight: 28
        radius: Theme.radiusBase
        opacity: enabled ? 1 : 0.4
        // A state layer over the item's own hover fill
        color: Theme.alpha(Theme.textColor, tap.pressed ? Theme.statePressed : hover.hovered ? Theme.stateHover : 0)

        Icon {
            anchors.centerIn: parent
            size: control.glyphSize
            text: control.glyph
        }

        HoverHandler {
            id: hover
        }
        TapHandler {
            id: tap

            onTapped: control.tapped()
        }
    }
}
