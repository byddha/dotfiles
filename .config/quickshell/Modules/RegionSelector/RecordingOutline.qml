import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"

// Viewfinder corners, a timer and a light dim around the area being recorded, all kept a gap
// outside it so the recording never contains them. Takes no input: clicks and keys go to whatever is under it.
Scope {
    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: window

            required property ShellScreen modelData
            readonly property var monitorInfo: Compositor.monitorForScreen(modelData)
            readonly property rect local: Qt.rect(Recording.region.x - (monitorInfo?.x ?? 0), Recording.region.y - (monitorInfo?.y ?? 0), Recording.region.width, Recording.region.height)
            // Wider than the corner shadow (blur 4), plus a pixel for rounding on scaled monitors
            readonly property int gap: 6
            readonly property int thickness: 3

            screen: modelData
            visible: Recording.recording && Recording.region.width > 0 && local.x < modelData.width && local.y < modelData.height && local.x + local.width > 0 && local.y + local.height > 0

            WlrLayershell.namespace: "bidshell:recordingOutline"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Light dim everywhere except the recorded area plus the gap (four bands around that hole)
            Item {
                id: hole
                x: window.local.x - window.gap
                y: window.local.y - window.gap
                width: window.local.width + window.gap * 2
                height: window.local.height + window.gap * 2
            }
            DimBand {
                width: parent.width
                height: Math.max(0, hole.y)
            }
            DimBand {
                y: hole.y + hole.height
                width: parent.width
                height: Math.max(0, parent.height - y)
            }
            DimBand {
                y: hole.y
                width: Math.max(0, hole.x)
                height: hole.height
            }
            DimBand {
                x: hole.x + hole.width
                y: hole.y
                width: Math.max(0, parent.width - x)
                height: hole.height
            }

            // The corners' outer edges, gap outside the recorded area
            Item {
                id: frame
                x: window.local.x - window.gap - window.thickness
                y: window.local.y - window.gap - window.thickness
                width: window.local.width + (window.gap + window.thickness) * 2
                height: window.local.height + (window.gap + window.thickness) * 2

                Corner {
                    anchors.left: parent.left
                    anchors.top: parent.top
                }
                Corner {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    rotation: 90
                }
                Corner {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    rotation: 180
                }
                Corner {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    rotation: 270
                }
            }

            // Timer above the top-left corner, or below the bottom-left one when there is no room;
            // hidden when neither fits (it must never be inside the recording)
            Rectangle {
                id: timerPill

                readonly property real above: frame.y - height - 6
                readonly property real below: frame.y + frame.height + 6
                property int elapsed: 0

                visible: above >= 0 || below + height <= window.modelData.height
                x: Math.max(0, frame.x)
                y: above >= 0 ? above : below
                width: timerRow.implicitWidth + 20
                height: timerRow.implicitHeight + 8
                radius: height / 2
                color: Qt.rgba(0, 0, 0, 0.7)

                Timer {
                    running: window.visible
                    repeat: true
                    triggeredOnStart: true
                    interval: 500
                    onTriggered: timerPill.elapsed = Math.max(0, Math.floor((Date.now() - Recording.startedAt) / 1000))
                }

                Row {
                    id: timerRow
                    anchors.centerIn: parent
                    spacing: 7

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: Theme.accentRed
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: "white"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBase
                        font.weight: Font.Medium
                        text: {
                            const m = Math.floor(timerPill.elapsed / 60);
                            return `${String(m).padStart(2, "0")}:${String(timerPill.elapsed % 60).padStart(2, "0")}`;
                        }
                    }

                    Text {
                        visible: Recording.hasAudio
                        anchors.verticalCenter: parent.verticalCenter
                        color: "white"
                        font.family: Theme.fontFamilyGlyphs
                        font.pixelSize: Theme.fontSizeBase
                        text: Icons.volumeHigh
                    }

                    Text {
                        visible: Recording.hasMic
                        anchors.verticalCenter: parent.verticalCenter
                        color: "white"
                        font.family: Theme.fontFamilyGlyphs
                        font.pixelSize: Theme.fontSizeBase
                        text: Icons.microphone
                    }
                }
            }
        }
    }

    component DimBand: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.2)
    }

    // Top-left L; the other corners rotate it
    component Corner: Item {
        readonly property int thickness: 3
        readonly property int length: 18

        width: length
        height: length

        RectangularShadow {
            anchors.fill: horizontal
            radius: horizontal.radius
            blur: 4
            color: Qt.rgba(0, 0, 0, 0.5)
        }
        RectangularShadow {
            anchors.fill: vertical
            radius: vertical.radius
            blur: 4
            color: Qt.rgba(0, 0, 0, 0.5)
        }

        Rectangle {
            id: horizontal
            width: parent.length
            height: parent.thickness
            radius: height / 2
            color: "white"
        }
        Rectangle {
            id: vertical
            width: parent.thickness
            height: parent.length
            radius: width / 2
            color: "white"
        }
    }
}
