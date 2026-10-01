import QtQuick
import "../../Components"

// mm:ss since a moment (ms since epoch), ticking while visible
StyledText {
    id: root

    property double since: 0
    property double now: Date.now()

    readonly property int seconds: since > 0 ? Math.max(0, Math.floor((now - since) / 1000)) : 0

    text: {
        const h = Math.floor(seconds / 3600);
        const m = String(Math.floor((seconds % 3600) / 60)).padStart(2, "0");
        const s = String(seconds % 60).padStart(2, "0");
        return h > 0 ? `${h}:${m}:${s}` : `${m}:${s}`;
    }

    Timer {
        running: root.visible && root.since > 0
        repeat: true
        triggeredOnStart: true
        interval: 1000
        onTriggered: root.now = Date.now()
    }
}
