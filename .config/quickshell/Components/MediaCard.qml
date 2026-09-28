import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../Config"
import "../Services"

Rectangle {
    id: root

    property list<real> visualizerValues: []
    // Browsers often leave the length out
    readonly property string timeText: Media.length > 0 ? `${formatTime(Media.position)} / ${formatTime(Media.length)}` : formatTime(Media.position)

    radius: Theme.radiusBase
    color: Theme.cardSurface
    clip: true

    implicitHeight: 80

    // Blurred background art
    Image {
        id: blurredBg
        anchors.fill: parent
        source: Media.artUrl
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
        color: Theme.alpha(Theme.cardSurface, 0.75)
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingBase
        spacing: Theme.spacingBase

        // Album art
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: height
            radius: Theme.radiusBase - 2
            color: Theme.chipSurface
            clip: true

            Image {
                id: albumArt
                anchors.fill: parent
                source: Media.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }

            // Fallback icon
            Icon {
                anchors.centerIn: parent
                text: Lucide.music
                size: Theme.iconSizeLarge
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
            StyledText {
                Layout.fillWidth: true
                text: Media.title
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            // Artist
            StyledText {
                Layout.fillWidth: true
                role: "secondary"
                text: Media.artist
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                visible: text.length > 0
            }

            Item {
                Layout.fillHeight: true
            }

            StyledText {
                role: "secondary"
                text: root.timeText
                font.pixelSize: Theme.fontSizeTiny
            }

            // Audio visualizer
            AudioVisualizer {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                values: root.visualizerValues
                live: Media.playing
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
