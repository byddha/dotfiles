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
        layer.enabled: true
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
