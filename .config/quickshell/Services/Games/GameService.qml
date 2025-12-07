pragma Singleton

import QtQuick
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
    property string lastError: ""

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

    Connections {
        target: PlayTimeDb
        function onDataLoaded() {
            if (steamProvider.games.length > 0) {
                root.aggregateGames();
            }
        }
    }

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
        Logger.info("GameService: Refreshing all providers");
        root.isLoading = true;
        steamProvider.refresh();
    }

    function launchGame(game) {
        if (!game || !game.launchCommand) {
            Logger.error("GameService: Invalid game or launch command");
            return;
        }

        Logger.info(`GameService: Launching ${game.name}`);
        PlayTimeDb.recordPlay(game.id);
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
            const aLastPlayed = PlayTimeDb.getLastPlayed(a.id);
            const bLastPlayed = PlayTimeDb.getLastPlayed(b.id);
            if (bLastPlayed !== aLastPlayed) {
                return bLastPlayed - aLastPlayed;
            }
            return a.name.localeCompare(b.name);
        });

        root.games = all;
        root.lastError = steamProvider.lastError;

        Logger.info(`GameService: Total ${root.games.length} games loaded`);
    }

    Process {
        id: gameLauncher
        running: false

        onStarted: {
            Logger.info("GameService: Game process started");
        }

        onExited: (code, status) => {
            Logger.info(`GameService: Game process exited with code ${code}`);
        }
    }

    Component.onCompleted: {
        Logger.info("GameService initialized");
        Qt.callLater(refresh);
    }
}
