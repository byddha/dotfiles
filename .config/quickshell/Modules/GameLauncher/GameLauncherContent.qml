import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../Config"
import "../../Services"
import "../../Components"

Item {
    id: root

    // Animation timer
    property real shaderTime: 0
    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: root.shaderTime += 0.016
    }

    // Hero image source (hidden, used as shader input)
    Image {
        id: bgImage
        anchors.fill: parent
        source: gameCarousel.selectedGame?.heroArt ?? ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    // Animated bloom shader
    ShaderEffect {
        id: heroShader
        anchors.fill: parent
        visible: bgImage.status === Image.Ready
        opacity: 0.5

        property var source: bgImage
        property real time: root.shaderTime

        fragmentShader: "file:///home/bida/dotfiles/.config/quickshell/Modules/GameLauncher/shaders/hero_bloom.frag.qsb"

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
    }

    // Game stats panel - top left
    Column {
        id: statsPanel
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 30
        spacing: 12
        visible: gameCarousel.selectedGame
        width: 500

        // Helper functions
        function formatPlaytime(minutes) {
            if (!minutes || minutes === 0)
                return "Never played";
            const hours = Math.floor(minutes / 60);
            const mins = minutes % 60;
            if (hours > 0)
                return hours + "h " + mins + "m";
            return mins + "m";
        }

        function formatSize(bytes) {
            if (!bytes || bytes === 0)
                return "Unknown";
            const gb = bytes / (1024 * 1024 * 1024);
            if (gb >= 1)
                return gb.toFixed(1) + " GB";
            const mb = bytes / (1024 * 1024);
            return mb.toFixed(0) + " MB";
        }

        Row {
            spacing: 10
            Text {
                text: "Total Playtime"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
                width: 140
            }
            Text {
                text: statsPanel.formatPlaytime(gameCarousel.selectedGame?.playtime)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textColor
            }
        }

        Row {
            spacing: 10
            visible: (gameCarousel.selectedGame?.playtime2wks ?? 0) > 0
            Text {
                text: "Last 2 Weeks"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
                width: 140
            }
            Text {
                text: statsPanel.formatPlaytime(gameCarousel.selectedGame?.playtime2wks)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textColor
            }
        }

        Row {
            spacing: 10
            Text {
                text: "Install Size"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
                width: 140
            }
            Text {
                text: statsPanel.formatSize(gameCarousel.selectedGame?.sizeBytes)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textColor
            }
        }

        Row {
            spacing: 10
            Text {
                text: "Install Path"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
                width: 140
            }
            Text {
                text: gameCarousel.selectedGame?.installPath ?? ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textColor
                elide: Text.ElideMiddle
                width: statsPanel.width - 150
            }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 40
        spacing: Theme.spacingLarge

        // Game carousel - single row, centered
        GameCarousel {
            id: gameCarousel
            Layout.fillWidth: true
            Layout.preferredHeight: 350
        }

        SearchBar {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 400

            onNavigateLeft: gameCarousel.moveLeft()
            onNavigateRight: gameCarousel.moveRight()
            onActivateSelected: {
                if (gameCarousel.selectedGame) {
                    GameService.launchGame(gameCarousel.selectedGame);
                    Settings.gameLauncherVisible = false;
                }
            }
        }
    }
}
