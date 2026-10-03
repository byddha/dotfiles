pragma ComponentBehavior: Bound

// Qualified: QtCore has a Settings type of its own, which would hide the shell's Settings
import QtCore as QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Utils"

/**
 * Wallpaper - The image or video from monitors.<key>.wallpaper behind everything, on each monitor
 * that sets one.
 *
 * A new wallpaper is revealed over the old one by a disc growing from a random point of the screen,
 * and the old one goes once the new one is shown. One that does not load keeps the old one.
 *
 * A video loops without sound at its own speed: a slower one is made as a file, where it gets the
 * frames that keep it smooth. It pauses while it cannot be seen: a fullscreen window on the
 * monitor, windows over all of the monitor beside the bar but their gaps, or
 * `qs ipc call wallpaper pause` from the idle daemon while the monitors are off.
 *
 * With monitors.<key>.wallpaperRecolor the wallpaper is first recolored with the theme palette
 * (lutgen, luminosity kept; a video through ffmpeg with a lutgen Hald CLUT), again on each theme
 * change. The result is cached under a name made from the file's bytes and the palette, so a new
 * theme or a new file is always a new name: nothing has to notice a file changing in place, and a
 * half-written file is never shown.
 */
Variants {
    id: root

    readonly property string cacheDir: QtCore.StandardPaths.standardLocations(QtCore.StandardPaths.CacheLocation)[0].toString().replace("file://", "") + "/bidshell/wallpaper"

    // $1 image or video, $2 cache dir, $3 file name prefix, $4 "png" or "mp4", then the palette.
    // Prints the recolored file and removes the prefix's other files, so each monitor keeps one.
    readonly property string recolorScript: `
        src=$1 dir=$2 prefix=$3 ext=$4
        shift 4
        key=$({ sha256sum < "$src" && printf "%s\\n" "$@"; } | sha256sum | cut -c1-16) || exit 1
        out="$dir/$prefix-$key.$ext"
        if [ ! -f "$out" ]; then
            tmp="$dir/$prefix-$key.tmp.$ext" lut="$dir/$prefix-$key.lut.png"
            mkdir -p "$dir" || exit 1
            if [ "$ext" = mp4 ]; then
                lutgen generate -P -o "$lut" -- "$@" >&2 &&
                    ffmpeg -v error -y -i "$src" -i "$lut" -filter_complex "[0:v][1:v]haldclut" -an \\
                        -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p -movflags +faststart "$tmp"
            else
                lutgen apply -P -o "$tmp" "$src" -- "$@" >&2
            fi && mv -f "$tmp" "$out"
            status=$?
            rm -f "$tmp" "$lut"
            [ $status -eq 0 ] || exit 1
        fi
        find "$dir" -maxdepth 1 -name "$prefix-*" ! -path "$out" -delete
        echo "$out"`

    // Made on the first video, so that without QtMultimedia only videos fail
    property Component videoComponent: null

    // Each window counts as this much bigger on every side, so the gaps between windows and along
    // the edges are not seen as wallpaper; a share of the monitor would miss them on a small one
    readonly property real gapTolerance: 32
    readonly property real hiddenCoverage: 0.99

    // How much of area [x1, y1, x2, y2] the rects [x1, y1, x2, y2] cover together, 0..1
    function coverage(rects, area) {
        const clipped = rects.map(r => [Math.max(r[0], area[0]), Math.max(r[1], area[1]), Math.min(r[2], area[2]), Math.min(r[3], area[3])]).filter(r => r[0] < r[2] && r[1] < r[3]);
        // The QML engine has no Array.flatMap
        const xs = [...new Set(clipped.map(r => r[0]).concat(clipped.map(r => r[2])))].sort((a, b) => a - b);
        let covered = 0;
        for (let i = 0; i + 1 < xs.length; i++) {
            const spans = clipped.filter(r => r[0] <= xs[i] && r[2] >= xs[i + 1]).map(r => [r[1], r[3]]).sort((a, b) => a[0] - b[0]);
            // Spans sorted by top: each adds only what lies below the lowest edge so far
            let height = 0, bottom = -Infinity;
            for (const [y1, y2] of spans) {
                height += Math.max(0, y2 - Math.max(y1, bottom));
                bottom = Math.max(bottom, y2);
            }
            covered += (xs[i + 1] - xs[i]) * height;
        }
        return covered / ((area[2] - area[0]) * (area[3] - area[1]));
    }

    function isVideo(path) {
        return /\.(mp4|webm|mkv|mov)$/i.test(path);
    }

    function configFor(screen) {
        return Config.options.monitors?.[Compositor.monitorFor(screen)?.key ?? ""];
    }

    function pathFor(screen) {
        const path = configFor(screen)?.wallpaper ?? "";
        return path.startsWith("~/") ? Quickshell.env("HOME") + path.slice(1) : path;
    }

    model: Quickshell.screens.filter(screen => pathFor(screen) !== "")

    PanelWindow {
        id: window

        required property ShellScreen modelData
        readonly property string key: Compositor.monitorFor(modelData)?.key ?? ""
        readonly property string path: root.pathFor(modelData)
        readonly property bool recolor: root.configFor(modelData)?.wallpaperRecolor === true
        // What the recolor job is for; empty when there is none to run
        readonly property string recolorJob: recolor && path !== "" && key !== "" && ThemeService.imagePalette !== "" ? JSON.stringify([key, path, ThemeService.imagePalette]) : ""
        property string recolored: ""
        readonly property string shown: recolor ? recolored : path
        // Each path segment encoded, so a "#" or "?" in a file name stays part of the name
        readonly property string source: "file://" + shown.split("/").map(encodeURIComponent).join("/")
        // The image or video shown; each has ready, true once it can be revealed
        property Item current
        readonly property int revealDuration: 1000
        // Nothing of the wallpaper is seen: windows of the shown workspace drawn over it
        readonly property bool hidden: {
            const monitor = Compositor.monitorFor(modelData);
            if (!monitor)
                return false;
            const shown = Compositor.windowsOn(monitor.activeWorkspaceId);
            if (shown.some(w => w.fullscreen))
                return true;
            if (!Compositor.hasWindowGeometry)
                return false;
            // The bar's own size, not the compositor's reserved area: Hyprland reports the bar's space
            // only after some later monitor event, so at startup the bar strip would count as wallpaper
            const bar = side => BarLayout.reservedAt(side);
            const area = [monitor.x + bar("left"), monitor.y + bar("top"), monitor.x + monitor.width - bar("right"), monitor.y + monitor.height - bar("bottom")];
            const g = root.gapTolerance;
            return root.coverage(shown.map(w => [w.x - g, w.y - g, w.x + w.width + g, w.y + w.height + g]), area) >= root.hiddenCoverage;
        }
        readonly property bool playing: !hidden && !Settings.wallpaperPaused

        screen: modelData
        color: "transparent"
        mask: Region {}

        WlrLayershell.namespace: "bidshell:wallpaper"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Also called when the source is reported changed to the value it already has, and with an
        // empty path while the window is going away
        function show() {
            if (shown === "" || current?.source.toString() === source)
                return;
            if (!root.isVideo(shown)) {
                current = image.createObject(window.contentItem, {
                    source: source,
                    revealFrom: Qt.point(Math.random(), Math.random())
                });
                return;
            }
            if (!root.videoComponent)
                root.videoComponent = Qt.createComponent("WallpaperVideo.qml");
            if (root.videoComponent.status === Component.Error) {
                Logger.error("Wallpaper video not shown:", root.videoComponent.errorString());
                return;
            }
            current = root.videoComponent.createObject(window.contentItem, {
                source: source,
                host: window,
                revealFrom: Qt.point(Math.random(), Math.random())
            });
        }

        // One job at a time: a job that ends after the next one started would delete that one's
        // file. A job that changed while one ran starts when it ends.
        function startRecolor() {
            if (recolorProcess.running || recolorJob === "" || recolorProcess.job === recolorJob)
                return;
            recolorProcess.job = recolorJob;
            recolorProcess.command = ["bash", "-c", root.recolorScript, "bidshell-wallpaper", path, root.cacheDir, key, root.isVideo(path) ? "mp4" : "png", ...ThemeService.imagePalette.split(" ")];
            recolorProcess.running = true;
        }

        // Later in the same turn: a config change sets wallpaper and wallpaperRecolor one after
        // the other, and the source between the two is neither the old nor the new one
        onSourceChanged: Qt.callLater(show)
        onRecolorJobChanged: {
            if (recolorJob === "" && key !== "") {
                recolored = "";
                recolorProcess.job = "";
                Quickshell.execDetached(["find", root.cacheDir, "-maxdepth", "1", "-name", key + "-*", "-delete"]);
            }
            startRecolor();
        }
        Component.onCompleted: {
            startRecolor();
            show();
        }

        Process {
            id: recolorProcess

            property string job: ""

            stdout: StdioCollector {
                id: recolorOut
            }
            stderr: StdioCollector {
                id: recolorErr
            }

            onExited: code => {
                if (job === window.recolorJob) {
                    if (code === 0)
                        window.recolored = recolorOut.text.trim();
                    else
                        Logger.error("Wallpaper not recolored:", window.path, recolorErr.text.trim());
                }
                window.startRecolor();
            }
        }

        Component {
            id: image

            Image {
                id: img

                readonly property bool ready: status === Image.Ready
                property real reveal: 0
                // Where on the screen the reveal starts, 0..1
                property point revealFrom: Qt.point(0.5, 0.5)

                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                // Decoded at the monitor's pixel size, not the file's
                sourceSize: Qt.size(width * window.devicePixelRatio, height * window.devicePixelRatio)

                // Only while revealed: a layer renders the image once more on each change
                layer.enabled: reveal < 1
                layer.effect: DiscReveal {
                    progress: img.reveal
                    center: img.revealFrom
                }

                onStatusChanged: {
                    if (status === Image.Error)
                        Logger.warn("Wallpaper not loaded:", source);
                }

                NumberAnimation on reveal {
                    running: img.ready
                    to: 1
                    duration: window.revealDuration
                    easing.type: Easing.InOutCubic
                }

                // Older wallpapers go once a newer one is shown; one that failed to load never is,
                // so the one before it stays
                Timer {
                    running: window.current !== img && window.current?.ready === true
                    interval: window.revealDuration
                    onTriggered: img.destroy()
                }
            }
        }
    }
}
