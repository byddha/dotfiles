import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import "../Config"
import "../Services"

Rectangle {
    id: root

    property MprisPlayer player: MprisController.activePlayer
    property bool showControls: true
    property bool showVisualizer: false
    property list<real> visualizerValues: []
    property bool compact: false

    radius: Theme.radiusBase
    color: Theme.colLayer1
    clip: true

    implicitHeight: compact ? 60 : 80

    // Blurred background art
    Image {
        id: blurredBg
        anchors.fill: parent
        source: root.player?.trackArtUrl ?? ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true

        layer.enabled: status === Image.Ready
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 32
        }
    }

    // Overlay for readability (always visible)
    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.colLayer1, 0.75)
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: compact ? Theme.spacingBase / 2 : Theme.spacingBase
        spacing: Theme.spacingBase

        // Album art
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: height
            radius: Theme.radiusBase - 2
            color: Theme.colLayer2
            clip: true

            Image {
                id: albumArt
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }

            // Fallback icon
            Text {
                anchors.centerIn: parent
                text: Icons.musicAlt
                font.family: Theme.fontFamilyIcons
                font.pixelSize: compact ? 20 : 28
                color: Theme.textSecondary
                visible: albumArt.status !== Image.Ready
            }
        }

        // Info column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            // Track title
            Text {
                Layout.fillWidth: true
                text: root.player?.trackTitle ?? "No track"
                font.family: Theme.fontFamily
                font.pixelSize: compact ? Theme.fontSizeSmall : Theme.fontSizeBase
                font.bold: true
                color: Theme.textColor
                elide: Text.ElideRight
            }

            // Artist
            Text {
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
                elide: Text.ElideRight
                visible: text.length > 0
            }

            Item {
                Layout.fillHeight: true
            }

            // Playback controls
            RowLayout {
                visible: root.showControls
                spacing: Theme.spacingBase

                // Previous
                Text {
                    text: Icons.skipPrevious
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: compact ? 16 : 20
                    color: prevArea.containsMouse ? Theme.primary : Theme.textSecondary
                    opacity: root.player?.canGoPrevious ? 1 : 0.3

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player?.previous()
                    }
                }

                // Play/Pause
                Text {
                    text: root.player?.playbackState === MprisPlaybackState.Playing ? Icons.pause : Icons.play
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: compact ? 20 : 24
                    color: playArea.containsMouse ? Theme.primary : Theme.textColor

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player?.togglePlaying()
                    }
                }

                // Next
                Text {
                    text: Icons.skipNext
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: compact ? 16 : 20
                    color: nextArea.containsMouse ? Theme.primary : Theme.textSecondary
                    opacity: root.player?.canGoNext ? 1 : 0.3

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player?.next()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Time display
                Text {
                    text: formatTime(root.player?.position) + " / " + formatTime(root.player?.length)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.textSecondary
                    visible: root.player?.length > 0
                }
            }

            // Time display (when showing visualizer instead of controls)
            Text {
                visible: root.showVisualizer && !root.showControls
                text: formatTime(root.player?.position) + " / " + formatTime(root.player?.length)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.textSecondary
            }

            // Audio visualizer
            AudioVisualizer {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                visible: root.showVisualizer
                values: root.visualizerValues
                live: root.player?.playbackState === MprisPlaybackState.Playing
            }
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds <= 0)
            return "0:00";
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    }
}
