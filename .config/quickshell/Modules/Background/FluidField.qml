import QtQuick

// The velocity field the cursor stirs, at a quarter of the screen's size. It is stepped every frame
// only for a while after the cursor last moved, by when it has decayed to nothing: a still cursor
// costs nothing.
Item {
    id: root

    readonly property alias texture: fieldTexture
    readonly property bool active: settle.running

    // Pixels in this item
    property point cursor
    property point lastCursor

    // Qt repeats the hover position whenever the scene under the cursor changes, as on every video
    // frame; only a real move stirs the field
    function move(point) {
        if (point.x === cursor.x && point.y === cursor.y)
            return;
        if (!settle.running)
            lastCursor = point;
        cursor = point;
        settle.restart();
    }

    ShaderEffect {
        id: step

        width: Math.max(1, Math.round(root.width / 4))
        height: Math.max(1, Math.round(root.height / 4))
        // The step's own output from the last step
        property var field: fieldTexture
        property real dt: 1 / 60
        property real decay: 1.9
        property real aspect: root.width / Math.max(1, root.height)
        property real radius: 0.09
        property real swirl: 0.6
        property point texel: Qt.point(1 / width, 1 / height)
        property point cursor: Qt.point(root.cursor.x / Math.max(1, root.width), root.cursor.y / Math.max(1, root.height))
        property point push
        fragmentShader: Qt.resolvedUrl("shaders/fluid_step.frag.qsb")
    }

    ShaderEffectSource {
        id: fieldTexture

        sourceItem: step
        hideSource: true
        recursive: true
        live: root.active
        textureSize: Qt.size(step.width, step.height)
        format: ShaderEffectSource.RGBA16F
        wrapMode: ShaderEffectSource.ClampToEdge
    }

    Timer {
        id: settle
        interval: 4000
    }

    FrameAnimation {
        running: root.active
        onTriggered: {
            step.dt = Math.min(Math.max(frameTime, 0.001), 0.05);
            step.push = Qt.point((root.cursor.x - root.lastCursor.x) / root.width / step.dt, (root.cursor.y - root.lastCursor.y) / root.height / step.dt);
            root.lastCursor = root.cursor;
        }
    }
}
