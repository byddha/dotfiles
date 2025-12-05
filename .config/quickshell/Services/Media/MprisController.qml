pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../../Utils"

Singleton {
    id: root

    readonly property list<MprisPlayer> availablePlayers: Mpris.players.values

    // Manual selection index (-1 = auto-select)
    property int selectedIndex: -1

    // Sticky player mechanism - prevents flickering during track transitions
    property MprisPlayer _stickyPlayer: null
    property bool _inStickyPeriod: false

    Timer {
        id: stickyTimer
        interval: 2500  // 2.5 second sticky period
        onTriggered: root._inStickyPeriod = false
    }

    // Active player: manual selection or auto-select
    property MprisPlayer activePlayer: {
        // Manual selection takes priority
        if (selectedIndex >= 0 && selectedIndex < availablePlayers.length) {
            return availablePlayers[selectedIndex];
        }

        // Sticky period: prefer current player if still valid
        if (_inStickyPeriod && _stickyPlayer && availablePlayers.includes(_stickyPlayer)) {
            if (_stickyPlayer.canControl) {
                return _stickyPlayer;
            }
        }

        // Auto-select: prioritize playing, then controllable
        const playing = availablePlayers.find(p => p.playbackState === MprisPlaybackState.Playing);
        if (playing)
            return playing;

        const controllable = availablePlayers.find(p => p.canControl && p.canPlay);
        if (controllable)
            return controllable;

        return null;
    }

    // Stable player data - only updates when we have valid, complete data
    // UI components should bind to these for display to avoid flickering
    property string stableTrackTitle: ""
    property string stableTrackArtist: ""
    property string stableTrackArtUrl: ""
    property real stableTrackLength: 0
    property bool stableCanGoPrevious: false
    property bool stableCanGoNext: false
    property bool stableHasPlayer: false

    function updateStableData() {
        if (activePlayer && activePlayer.trackTitle) {
            stableTrackTitle = activePlayer.trackTitle;
            stableTrackArtist = activePlayer.trackArtist || "";
            stableTrackArtUrl = activePlayer.trackArtUrl || "";
            stableTrackLength = activePlayer.length || 0;
            stableCanGoPrevious = activePlayer.canGoPrevious || false;
            stableCanGoNext = activePlayer.canGoNext || false;
            stableHasPlayer = true;
            clearStableDataTimer.stop();
        } else {
            clearStableDataTimer.restart();
        }
    }

    Timer {
        id: clearStableDataTimer
        interval: 2500
        onTriggered: {
            if (!root.activePlayer || !root.activePlayer.trackTitle) {
                root.stableHasPlayer = false;
                root.stableTrackTitle = "";
                root.stableTrackArtist = "";
                root.stableTrackArtUrl = "";
                root.stableTrackLength = 0;
                root.stableCanGoPrevious = false;
                root.stableCanGoNext = false;
            }
        }
    }

    Connections {
        target: activePlayer
        function onTrackTitleChanged() {
            root.updateStableData();
        }
        function onTrackArtistChanged() {
            root.updateStableData();
        }
        function onTrackArtUrlChanged() {
            root.updateStableData();
        }
        function onLengthChanged() {
            root.updateStableData();
        }
        function onCanGoPreviousChanged() {
            root.updateStableData();
        }
        function onCanGoNextChanged() {
            root.updateStableData();
        }
    }

    // Cycle to next player
    function nextPlayer() {
        if (availablePlayers.length <= 1)
            return;
        if (selectedIndex < 0) {
            // Find current auto-selected player index
            const currentIdx = availablePlayers.indexOf(activePlayer);
            selectedIndex = (currentIdx + 1) % availablePlayers.length;
        } else {
            selectedIndex = (selectedIndex + 1) % availablePlayers.length;
        }
        Logger.info(`Switched to: ${activePlayer?.identity || "Unknown"}`);
    }

    // Cycle to previous player
    function previousPlayer() {
        if (availablePlayers.length <= 1)
            return;
        if (selectedIndex < 0) {
            const currentIdx = availablePlayers.indexOf(activePlayer);
            selectedIndex = (currentIdx - 1 + availablePlayers.length) % availablePlayers.length;
        } else {
            selectedIndex = (selectedIndex - 1 + availablePlayers.length) % availablePlayers.length;
        }
        Logger.info(`Switched to: ${activePlayer?.identity || "Unknown"}`);
    }

    // Reset to auto-select when players change
    onAvailablePlayersChanged: {
        if (selectedIndex >= availablePlayers.length) {
            selectedIndex = -1;
        }
    }

    Component.onCompleted: {
        Logger.info("MPRIS service initialized");
        Logger.info(`Available players: ${availablePlayers.length}`);
    }

    onActivePlayerChanged: {
        // Update stable data
        updateStableData();

        if (activePlayer) {
            Logger.debug("Active player:", activePlayer.identity || "Unknown");
        } else {
            Logger.debug("No active player");
        }

        // Defer sticky state update to break binding loop
        // (_stickyPlayer is read in activePlayer binding, so writing it directly causes a loop)
        Qt.callLater(() => {
            if (activePlayer && activePlayer !== _stickyPlayer) {
                _stickyPlayer = activePlayer;
                _inStickyPeriod = true;
                stickyTimer.restart();
            }
        });
    }
}
