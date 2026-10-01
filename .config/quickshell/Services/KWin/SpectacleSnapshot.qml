import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// One still frame of a screen: spectacle takes the whole desktop, and the Image shows this screen's part of it
Item {
    id: root

    property var screen
    readonly property bool hasContent: image.status === Image.Ready
    property string path: ""

    // The desktop picture is in physical pixels at the largest scale of any screen; this screen's rect in it
    readonly property rect sourceRect: {
        const monitors = Quickshell.screens.map(s => Compositor.monitorFor(s)).filter(m => m);
        const monitor = Compositor.monitorFor(screen);
        if (!monitor || monitors.length === 0)
            return Qt.rect(0, 0, 0, 0);
        const scale = Math.max(...monitors.map(m => m.scale));
        const left = Math.min(...monitors.map(m => m.x));
        const top = Math.min(...monitors.map(m => m.y));
        return Qt.rect(Math.round((monitor.x - left) * scale), Math.round((monitor.y - top) * scale), Math.round(monitor.width * scale), Math.round(monitor.height * scale));
    }

    onScreenChanged: {
        if (!screen || capture.running)
            return;
        path = `${Quickshell.env("XDG_RUNTIME_DIR")}/bidshell-snapshot-${screen.name}.png`;
        capture.command = ["spectacle", "--background", "--nonotify", "--fullscreen", "--output", path];
        capture.running = true;
    }
    Component.onDestruction: if (path)
        Quickshell.execDetached(["rm", "-f", path])

    Process {
        id: capture

        onExited: image.source = `file://${root.path}`
    }

    Image {
        id: image

        anchors.fill: parent
        cache: false
        sourceClipRect: root.sourceRect
        onStatusChanged: if (status === Image.Ready)
            Quickshell.execDetached(["rm", "-f", root.path])
    }
}
