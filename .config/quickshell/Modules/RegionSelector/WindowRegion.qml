import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Services"

Rectangle {
    id: root

    required property var clientDimensions
    property bool targeted: false
    // Cutout regions for floating windows (in local coordinates)
    // Each item should be {x, y, width, height} or null
    property var cutouts: []

    x: clientDimensions.at[0]
    y: clientDimensions.at[1]
    width: clientDimensions.size[0]
    height: clientDimensions.size[1]

    color: "transparent"
    radius: Theme.roundingWindow
    clip: true  // For precise AA rounded corners: use layer.effect + SDF shader (roundedBoxSDF)
    visible: opacity > 0

    // Helper to get cutout at index, or zero vector if not present
    function getCutout(index) {
        if (index < cutouts.length && cutouts[index]) {
            const c = cutouts[index];
            return Qt.vector4d(c.x, c.y, c.width, c.height);
        }
        return Qt.vector4d(0, 0, 0, 0);
    }

    // Shader-based hatching with rounded corners
    ShaderEffect {
        anchors.fill: parent
        visible: !root.targeted

        property real overlayOpacity: 0.85
        property real hatchOpacity: 1.0
        property real hatchSpacing: 16.0
        property color overlayColor: Theme.colLayer0
        property color hatchColor: Theme.textColor
        property vector4d selection: Qt.vector4d(0, 0, 0, 0)
        property vector4d resolutionAndRadius: Qt.vector4d(root.width, root.height, Theme.roundingWindow, 0)
        // Floating window cutouts
        property vector4d cutout1: root.getCutout(0)
        property vector4d cutout2: root.getCutout(1)
        property vector4d cutout3: root.getCutout(2)
        property vector4d cutout4: root.getCutout(3)

        fragmentShader: "shaders/selection_overlay.frag.qsb"
    }

    // Window class label
    Rectangle {
        visible: root.targeted
        anchors.centerIn: parent
        radius: Theme.radiusBase
        color: Theme.colLayer0
        border.color: Theme.primary
        border.width: 2
        width: labelRow.width + 24
        height: labelRow.height + 16

        RowLayout {
            id: labelRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                id: iconText
                text: AppIcons.getIcon(root.clientDimensions.class, root.clientDimensions.title, "")
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 22
                color: Theme.primary
            }

            Text {
                id: classText
                text: AppIcons.getDisplayName(root.clientDimensions.class, root.clientDimensions.title, "") || root.clientDimensions.class || "Window"
                font.family: Theme.fontFamily
                font.pixelSize: 24
                font.weight: Font.Medium
                color: Theme.textColor
            }
        }
    }
}
