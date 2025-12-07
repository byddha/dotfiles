pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "../../Utils"

Singleton {
    id: root

    readonly property string cacheDir: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] + "/bidshell"
    readonly property string filePath: cacheDir + "/game_playtime.json"

    property var data: ({})
    property bool loaded: false

    signal dataLoaded

    function getLastPlayed(gameId) {
        return data[gameId] || 0;
    }

    function recordPlay(gameId) {
        const timestamp = Math.floor(Date.now() / 1000);
        data[gameId] = timestamp;
        save();
        Logger.info(`PlayTimeDb: Recorded play for ${gameId}`);
    }

    function save() {
        playtimeFileView.setText(JSON.stringify(data, null, 2));
    }

    function load() {
        playtimeFileView.reload();
    }

    Component.onCompleted: {
        load();
    }

    FileView {
        id: playtimeFileView
        path: root.filePath
        printErrors: false

        onLoaded: {
            try {
                root.data = JSON.parse(playtimeFileView.text());
                Logger.info(`PlayTimeDb: Loaded ${Object.keys(root.data).length} entries`);
            } catch (e) {
                Logger.error(`PlayTimeDb: Failed to parse JSON: ${e}`);
                root.data = {};
            }
            root.loaded = true;
            root.dataLoaded();
        }

        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                Logger.info("PlayTimeDb: No file found, creating empty database");
                root.data = {};
                root.save();
            } else {
                Logger.error(`PlayTimeDb: Error loading file: ${error}`);
                root.data = {};
            }
            root.loaded = true;
            root.dataLoaded();
        }
    }
}
