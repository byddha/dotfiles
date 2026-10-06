import QtQuick
import Qt.labs.folderlistmodel
import Quickshell

// The wallpaper the shell shows on this monitor, recolored when the shell recolors it
Item {
    id: root

    required property ShellScreen screen
    property bool playing: true

    readonly property string key: LockConfig.keyOf(screen)
    readonly property var monitor: LockConfig.monitors[key]
    readonly property string path: {
        const path = monitor?.wallpaper ?? "";
        return path.startsWith("~/") ? Quickshell.env("HOME") + path.slice(1) : path;
    }
    readonly property string recoloredPath: {
        // A recolor in progress also leaves .tmp and .lut files under the monitor's prefix
        for (let i = 0; i < recolored.count; i++) {
            const name = recolored.get(i, "fileName");
            if (!name.includes(".tmp.") && !name.includes(".lut."))
                return recolored.get(i, "filePath");
        }
        return "";
    }
    readonly property string shown: monitor?.wallpaperRecolor === true ? recoloredPath : path
    readonly property bool video: /\.(mp4|webm|mkv|mov)$/i.test(shown)
    // Each path segment encoded, so a "#" or "?" in a file name stays part of the name
    readonly property string source: shown === "" ? "" : "file://" + shown.split("/").map(encodeURIComponent).join("/")

    // What WallpaperVideo asks of the wallpaper window (and `playing`): here a video is always the
    // current one, shown at once
    readonly property int revealDuration: 0
    readonly property Item current: videoLoader.item

    FolderListModel {
        id: recolored

        folder: "file://" + LockConfig.cacheDir
        nameFilters: [root.key + "-*"]
        showDirs: false
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    Image {
        anchors.fill: parent
        visible: !root.video
        source: root.video ? "" : root.source
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        // Decoded at the monitor's pixel size: a large file decoded at its own size can pass
        // Qt's image allocation limit and not load at all
        // A lock surface gets its screen only after it is made
        sourceSize: Qt.size(width * (root.screen?.devicePixelRatio ?? 1), height * (root.screen?.devicePixelRatio ?? 1))
    }

    // By URL, not as a type: without QtMultimedia only a video fails, not the whole lock
    Loader {
        id: videoLoader

        anchors.fill: parent
    }

    // WallpaperVideo takes its file once, so a new file is a new one
    function loadVideo() {
        if (video)
            videoLoader.setSource(Qt.resolvedUrl("../Background/WallpaperVideo.qml"), {
                source: source,
                host: root,
                revealFrom: Qt.point(0.5, 0.5)
            });
        else
            videoLoader.source = "";
    }

    onSourceChanged: Qt.callLater(loadVideo)
    Component.onCompleted: loadVideo()
}
