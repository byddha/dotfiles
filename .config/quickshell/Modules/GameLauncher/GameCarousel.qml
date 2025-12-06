import QtQuick
import QtQuick.Controls
import "../../Config"
import "../../Services"

Item {
    id: root

    // Interleaved ordering: center-outward pattern
    // Most recent (0) -> center, 2nd (1) -> left, 3rd (2) -> right, etc.
    readonly property var interleavedGames: {
        const source = GameService.filteredGames;
        if (!source || source.length === 0)
            return [];

        const result = new Array(source.length);
        const center = Math.floor(source.length / 2);

        for (let i = 0; i < source.length; i++) {
            let targetPos;
            if (i === 0) {
                targetPos = center;  // Most recent -> center
            } else if (i % 2 === 1) {
                targetPos = center - Math.ceil(i / 2);  // Odd -> left of it
            } else {
                targetPos = center + (i / 2);  // Even -> right of it
            }
            result[targetPos] = source[i];
        }
        return result;
    }

    // Selection state - start at center (most recently played)
    property int selectedIndex: Math.floor(interleavedGames.length / 2)
    readonly property var selectedGame: interleavedGames[selectedIndex] ?? null
    readonly property int gameCount: interleavedGames.length

    // Reset selection when filter changes - start at center (most recently played)
    Connections {
        target: GameService
        function onFilteredGamesChanged() {
            root.selectedIndex = Math.floor(root.interleavedGames.length / 2);
            centerOnSelected();
        }
    }

    Component.onCompleted: {
        Qt.callLater(centerOnSelected);
    }

    // Navigation - wraps around
    function moveLeft() {
        if (gameCount === 0)
            return;
        selectedIndex = (selectedIndex - 1 + gameCount) % gameCount;
        centerOnSelected();
    }

    function moveRight() {
        if (gameCount === 0)
            return;
        selectedIndex = (selectedIndex + 1) % gameCount;
        centerOnSelected();
    }

    // No up/down for single row
    function moveUp() {
    }
    function moveDown() {
    }

    function centerOnSelected() {
        carousel.positionViewAtIndex(selectedIndex, ListView.Center);
    }

    ListView {
        id: carousel
        anchors.fill: parent
        anchors.topMargin: 20
        anchors.bottomMargin: 20

        orientation: ListView.Horizontal
        spacing: 20
        clip: false

        model: interleavedGames

        // Keep selected item centered
        preferredHighlightBegin: width / 2 - 100  // half of card width
        preferredHighlightEnd: width / 2 + 100
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 300

        delegate: GameCard {
            required property var modelData
            required property int index

            game: modelData
            isSelected: index === root.selectedIndex
            width: 200
            height: carousel.height - 40
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            text: GameService.isLoading ? "Loading games..." : GameService.searchQuery ? "No games found" : GameService.games.length === 0 ? "No Steam games detected" : ""
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBase
            color: Theme.textSecondary
            visible: carousel.count === 0
        }
    }
}
