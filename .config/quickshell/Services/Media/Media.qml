pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

/**
 * Media - The player the bar shows and controls, and the track it plays.
 *
 * The player that started playing last is the one shown. It stays while it is paused, and gives way
 * to the next most recent player still playing when it stops. The wheel on the bar item picks another.
 */
Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values.filter(p => isPlayer(p))
    property MprisPlayer player: null

    readonly property bool playing: player?.isPlaying ?? false
    readonly property real position: player?.position ?? 0
    readonly property bool canPrevious: player !== null && (player.canGoPrevious || player.canSeek)
    readonly property bool canNext: player?.canGoNext ?? false

    // The track, held steady against players that briefly blank or drop parts of it
    readonly property bool hasTrack: title !== ""
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property string url: ""
    // YouTube sends a Short's art as 16:9, with the vertical video in the middle between plain bars
    readonly property bool isShort: /^https:\/\/(www\.|m\.)?youtube\.com\/shorts\//.test(url)
    // Seconds; 0 when the player never said
    property real length: 0
    property string _trackKey: ""

    // Players in the order they last started playing, the most recent last
    property var _order: []

    function togglePlaying() {
        player?.togglePlaying();
    }

    // Past the first seconds of a track, previous starts it again, as music players do
    function previous() {
        if (!player)
            return;
        if (player.canSeek && player.position > 8)
            player.position = 0;
        else if (player.canGoPrevious)
            player.previous();
    }

    function next() {
        if (player?.canGoNext)
            player.next();
    }

    function cycle(step) {
        if (players.length < 2)
            return;
        const index = Math.max(0, players.indexOf(player));
        player = players[(index + step + players.length) % players.length];
    }

    // While the pointer rests on a YouTube thumbnail, Firefox (and Zen) publish the muted preview as
    // their one player, with the address of the page it is on. A video that really plays is always
    // on a watch, shorts, live or embed page.
    function isPreview(p) {
        if (!p.dbusName.startsWith("org.mpris.MediaPlayer2.firefox"))
            return false;
        const url = String(p.metadata["xesam:url"] ?? "");
        return /^https:\/\/(www\.|m\.)?youtube\.com\//.test(url) && !/^https:\/\/[^/]+\/(watch\?|shorts\/|live\/|embed\/)/.test(url);
    }

    // playerctld is not a player: it re-publishes whichever player it considers current, under its
    // own name and with a state that can lag behind the real one
    function isPlayer(p) {
        return p.dbusName !== "org.mpris.MediaPlayer2.playerctld";
    }

    function isLive(p) {
        return p.isPlaying && !isPreview(p);
    }

    function youtubeThumbnail(url) {
        const id = url.match(/^https:\/\/(?:www\.|m\.)?youtube\.com\/(?:watch\?(?:.*&)?v=|shorts\/|live\/|embed\/)([\w-]{11})/)?.[1];
        return id ? `https://i.ytimg.com/vi/${id}/mqdefault.jpg` : "";
    }

    function _latest(list) {
        return list.length > 0 ? list[list.length - 1] : null;
    }

    function _started(p) {
        _order = _order.filter(other => other !== p).concat([p]);
        player = p;
    }

    function _stopped(p) {
        if (p !== player)
            return;
        const next = _latest(_order.filter(other => other !== p && players.includes(other) && isLive(other)));
        if (next)
            player = next;
    }

    function _pick() {
        const present = _order.filter(p => players.includes(p));
        _order = present;
        if (player && players.includes(player))
            return;
        player = _latest(present.filter(p => isLive(p))) ?? _latest(present) ?? players.find(p => p.canControl && p.playbackState !== MprisPlaybackState.Stopped) ?? null;
    }

    function _syncTrack() {
        const p = player;
        if (!p) {
            clearTimer.stop();
            _clearTrack();
            return;
        }
        // Keep showing what played before the pointer came to rest on a thumbnail
        if (isPreview(p))
            return;
        // Read from the metadata itself: Quickshell signals it before trackTitle and the other
        // track properties follow
        const metadata = p.metadata;
        const trackTitle = String(metadata["xesam:title"] ?? "");
        if (!trackTitle) {
            // Chromium and Firefox blank the title for a moment between tracks and tabs
            if (!clearTimer.running)
                clearTimer.start();
            return;
        }
        clearTimer.stop();

        const url = String(metadata["xesam:url"] ?? "");
        const key = `${url}\n${trackTitle}`;
        const sameTrack = key === _trackKey;
        _trackKey = key;
        root.url = url;
        title = trackTitle;
        // A list by the spec; some players send a plain string
        const artists = metadata["xesam:artist"] ?? "";
        artist = (typeof artists === "string" ? artists : Array.from(artists).join(", ")) || (sameTrack ? artist : "");
        // Firefox blanks the art whenever a page updates its metadata without artwork (YouTube does
        // on ads and quality changes), and drops the length after every seek. Only the same track
        // may keep the previous value, so nothing from another track ever shows.
        artUrl = String(metadata["mpris:artUrl"] ?? "") || youtubeThumbnail(url) || (sameTrack ? artUrl : "");
        const lengthUs = Number(metadata["mpris:length"] ?? 0);
        length = lengthUs > 1e6 ? lengthUs / 1e6 : sameTrack ? length : 0;
    }

    function _clearTrack() {
        _trackKey = "";
        url = "";
        title = "";
        artist = "";
        artUrl = "";
        length = 0;
    }

    onPlayersChanged: _pick()
    onPlayerChanged: _syncTrack()
    Component.onCompleted: _pick()

    Timer {
        id: clearTimer

        interval: 2000
        onTriggered: {
            if (!root.player?.metadata["xesam:title"])
                root._clearTrack();
        }
    }

    // Quickshell works the position out from the last report but only signals it on a new report
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player.positionChanged()
    }

    Connections {
        target: root.player

        function onMetadataChanged() {
            root._syncTrack();
        }
    }

    // Mpris.players, not the filtered list: a new list on every change would rebuild every delegate,
    // and each playing player would count as just started, in list order
    Instantiator {
        model: Mpris.players

        delegate: QtObject {
            required property MprisPlayer modelData
            readonly property bool live: root.isPlayer(modelData) && root.isLive(modelData)

            onLiveChanged: live ? root._started(modelData) : root._stopped(modelData)
            Component.onCompleted: {
                if (live)
                    root._started(modelData);
            }
        }
    }
}
