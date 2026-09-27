pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "../../Utils"

/**
 * GameService - Central service for game library management
 *
 * Aggregates games from multiple providers (Steam, etc.)
 * Provides filtering, search, and launch capabilities.
 */
Singleton {
    id: root

    // ========================================================================
    // PUBLIC PROPERTIES
    // ========================================================================

    property var games: []
    property bool isLoading: false

    // Search/filter state
    property string searchQuery: ""

    // Computed filtered games
    property var filteredGames: {
        if (!searchQuery)
            return games;

        const query = searchQuery.toLowerCase();
        return games.filter(g => {
            // Match against name
            if (g.name.toLowerCase().includes(query))
                return true;
            // Match against abbreviations (e.g., "tlou" for "The Last of Us")
            if (g.abbreviations && g.abbreviations.some(abbr => abbr.includes(query)))
                return true;
            return false;
        });
    }

    // ========================================================================
    // PROVIDERS
    // ========================================================================

    SteamProvider {
        id: steamProvider
        onGamesChanged: root.aggregateGames()
        onIsLoadingChanged: root.isLoading = steamProvider.isLoading
    }

    // Add more providers here in the future:
    // HeroicProvider { id: heroicProvider; onGamesChanged: root.aggregateGames() }

    // ========================================================================
    // PUBLIC METHODS
    // ========================================================================

    function refresh() {
        root.isLoading = true;
        steamProvider.refresh();
    }

    function launchGame(game) {
        if (!game || !game.launchCommand) {
            Logger.error("GameService: Invalid game or launch command");
            return;
        }

        root.lastPlayed[game.id] = Math.floor(Date.now() / 1000);
        root.savePlaytime();
        gameLauncher.command = game.launchCommand;
        gameLauncher.running = true;
    }

    // ========================================================================
    // INTERNAL
    // ========================================================================

    function aggregateGames() {
        // Combine games from all providers
        let all = [...steamProvider.games];

        // Sort by lastPlayed (descending), then alphabetically
        all.sort((a, b) => {
            const aLastPlayed = root.lastPlayed[a.id] || 0;
            const bLastPlayed = root.lastPlayed[b.id] || 0;
            if (bLastPlayed !== aLastPlayed) {
                return bLastPlayed - aLastPlayed;
            }
            return a.name.localeCompare(b.name);
        });

        root.games = all;
    }

    Process {
        id: gameLauncher
    }

    // ========================================================================
    // PLAY TIME
    // ========================================================================

    // gameId -> unix timestamp of the last launch from here
    property var lastPlayed: ({})

    function savePlaytime() {
        playtimeFile.setText(JSON.stringify(root.lastPlayed, null, 2));
    }

    function aggregateIfLoaded() {
        if (steamProvider.games.length > 0)
            root.aggregateGames();
    }

    FileView {
        id: playtimeFile
        path: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] + "/bidshell/game_playtime.json"
        printErrors: false

        onLoaded: {
            try {
                root.lastPlayed = JSON.parse(playtimeFile.text());
            } catch (e) {
                Logger.error(`GameService: Failed to parse play time JSON: ${e}`);
                root.lastPlayed = {};
            }
            root.aggregateIfLoaded();
        }

        onLoadFailed: error => {
            root.lastPlayed = {};
            if (error == FileViewError.FileNotFound)
                root.savePlaytime();
            else
                Logger.error(`GameService: Error loading play time file: ${error}`);
            root.aggregateIfLoaded();
        }
    }

    Component.onCompleted: {
        playtimeFile.reload();
        Qt.callLater(refresh);
    }
}
