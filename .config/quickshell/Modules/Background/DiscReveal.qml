import QtQuick

// The layer effect that reveals a new wallpaper: a disc growing from a point of the screen
ShaderEffect {
    // 0 nothing shown, 1 all shown
    property real progress: 0
    // Where the disc starts inside the wallpaper item, 0..1
    property point center: Qt.point(0.5, 0.5)
    readonly property real aspect: width / Math.max(1, height)

    fragmentShader: Qt.resolvedUrl("shaders/disc_reveal.frag.qsb")
}
