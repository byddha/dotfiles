import QtQuick

// The velocity field the cursor stirs, at a quarter of the screen's size, stepped only for a while
// after the cursor last moved, by when it has decayed to nothing: a still cursor costs nothing.
//
// It moves in steps of a fixed length, as many as are due on each frame of its own window, so
// every monitor runs the same fluid: the field moves hundreds of pixels a second, and one long
// step on a 60 Hz monitor does not move it as four short ones on a 240 Hz one do.
Item {
    id: root

    required property real refreshRate
    readonly property real stepTime: 1 / 240
    // Each step due on a frame is one more pass in the chain, so a fast monitor has fewer of them.
    // The 0.05 keeps a 239.99 Hz monitor at one.
    readonly property int stageCount: Math.min(Math.ceil(1 / (refreshRate * stepTime) - 0.05), 4)
    property var texture
    // Not settle.running: a restart stops the timer for a moment, and each of those would start a
    // new stir
    property bool active: false

    // Pixels in this item: the cursor now, on the last frame, and at the last step
    property point cursor
    property point frameCursor
    property point stepCursor
    // Date.now() of the last frame, 0 before the first one
    property real lastFrame: 0
    // Seconds since the last step, at most one step
    property real pending: 0

    // Qt repeats the hover position whenever the scene under the cursor changes, as on every video
    // frame; only a real move stirs the field
    function move(point) {
        if (point.x === cursor.x && point.y === cursor.y)
            return;
        cursor = point;
        if (!active) {
            frameCursor = point;
            stepCursor = point;
            lastFrame = 0;
            pending = 0;
            active = true;
        }
        settle.restart();
    }

    // Each stage reads the one before it; the first reads the last, which is the field
    function chain() {
        // count is the model's: the items are added one by one after it is set
        for (let i = 0; i < stages.count; i++) {
            if (!stages.itemAt(i))
                return;
        }
        for (let i = 0; i < stages.count; i++)
            stages.itemAt(i).field = stages.itemAt((i + stages.count - 1) % stages.count).texture;
        texture = stages.itemAt(stages.count - 1).texture;
    }

    component Stage: Item {
        property alias field: shader.field
        property alias dt: shader.dt
        property alias cursor: shader.cursor
        property alias push: shader.push
        readonly property alias texture: output

        function redraw() {
            shader.update();
        }

        ShaderEffect {
            id: shader

            width: Math.round(root.width / 4)
            height: Math.round(root.height / 4)
            property var field
            // 0 for a step not due on this frame
            property real dt: 0
            property real decay: 1.9
            property real diffusion: 36
            property real aspect: root.width / root.height
            // A share of the screen's height, so that it covers the same part of the wallpaper on
            // every monitor
            property real radius: 0.07
            property real swirl: 0.42
            property point texel: Qt.point(1 / width, 1 / height)
            property point cursor
            property point push
            fragmentShader: Qt.resolvedUrl("shaders/fluid_step.frag.qsb")
        }

        // Recursive keeps it drawn on every frame while live, even when its own inputs did not
        // change, and lets the first stage read the last one while that one is drawn
        ShaderEffectSource {
            id: output

            sourceItem: shader
            hideSource: true
            recursive: true
            live: root.active
            textureSize: Qt.size(shader.width, shader.height)
            format: ShaderEffectSource.RGBA16F
            wrapMode: ShaderEffectSource.ClampToEdge
        }
    }

    Repeater {
        id: stages

        model: root.stageCount
        delegate: Stage {}
        onItemAdded: root.chain()
        onItemRemoved: root.chain()
    }

    Timer {
        id: settle
        interval: 4000
        onTriggered: root.active = false
    }

    // Only keeps the window drawing while the field moves. The steps are not taken here: a
    // FrameAnimation ticks with the fastest monitor, not with this window's frames.
    FrameAnimation {
        running: root.active
        onTriggered: {
            for (let i = 0; i < stages.count; i++)
                stages.itemAt(i).redraw();
        }
    }

    Connections {
        target: root.Window.window
        enabled: root.active

        function onAfterAnimating() {
            const now = Date.now();
            // The first frame of a stir takes one step
            const frame = root.lastFrame ? (now - root.lastFrame) / 1000 : root.stepTime;
            root.lastFrame = now;
            const before = root.pending;
            const due = Math.min(Math.floor((before + frame) / root.stepTime), stages.count);
            let from = root.stepCursor;
            for (let i = 0; i < stages.count; i++) {
                const stage = stages.itemAt(i);
                if (i >= due) {
                    stage.dt = 0;
                    stage.push = Qt.point(0, 0);
                    continue;
                }
                // The cursor went straight from frameCursor to cursor during the frame. Two frames can
                // come in the same millisecond, with a whole step pending: 0 / 0 would put NaN in
                // the field, and the wallpaper would draw grey until the stir ends.
                const at = frame > 0 ? ((i + 1) * root.stepTime - before) / frame : 1;
                const to = Qt.point(root.frameCursor.x + (root.cursor.x - root.frameCursor.x) * at, root.frameCursor.y + (root.cursor.y - root.frameCursor.y) * at);
                stage.dt = root.stepTime;
                stage.cursor = Qt.point(to.x / root.width, to.y / root.height);
                stage.push = Qt.point((to.x - from.x) / root.width / root.stepTime, (to.y - from.y) / root.height / root.stepTime);
                from = to;
            }
            root.stepCursor = from;
            root.frameCursor = root.cursor;
            // A frame longer than the steps it can take loses the rest: the fluid slows, not jumps
            root.pending = Math.min(before + frame - due * root.stepTime, root.stepTime);
        }
    }
}
