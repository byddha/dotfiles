import QtQuick

// The layer effect that pulls the wallpaper along a FluidField
ShaderEffect {
    property var field
    property real warp: 0.08
    property real split: 0.25

    fragmentShader: Qt.resolvedUrl("shaders/fluid_warp.frag.qsb")
}
