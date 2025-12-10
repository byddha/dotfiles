import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Services"

Rectangle {
    id: root

    required property var clientDimensions
    property bool targeted: false

    x: clientDimensions.at[0]
    y: clientDimensions.at[1]
    width: clientDimensions.size[0]
    height: clientDimensions.size[1]

    color: "transparent"
    radius: Theme.roundingWindow
    clip: true  // For precise AA rounded corners: use layer.effect + SDF shader (roundedBoxSDF)
    visible: opacity > 0

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
