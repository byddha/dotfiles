import QtQuick
import "../../Config"

Item {
    id: root

    required property real regionX
    required property real regionY
    required property real regionWidth
    required property real regionHeight
    required property real mouseX
    required property real mouseY

    property color overlayColor: Theme.colLayer0
    property real overlayOpacity: 0.85
    property color selectionColor: Theme.primary
    property color hatchColor: Theme.textColor
    property real hatchOpacity: 1
    property real hatchSpacing: 12.0

    // GPU-rendered overlay with hatching
    ShaderEffect {
        anchors.fill: parent

        // Properties must match shader uniform order (std140 layout)
        property real overlayOpacity: root.overlayOpacity
        property real hatchOpacity: root.hatchOpacity
        property real hatchSpacing: root.hatchSpacing
        property color overlayColor: root.overlayColor
        property color hatchColor: root.hatchColor
        property vector4d selection: Qt.vector4d(root.regionX, root.regionY, root.regionWidth, root.regionHeight)
        property vector4d resolutionAndRadius: Qt.vector4d(root.width, root.height, 0, 0)  // No corner rounding for fullscreen

        fragmentShader: "shaders/selection_overlay.frag.qsb"
    }

    // Selection border
    Rectangle {
        id: selectionBorder
        x: root.regionX
        y: root.regionY
        width: root.regionWidth
        height: root.regionHeight
        color: "transparent"
        border.color: root.selectionColor
        border.width: 2
    }

    // Dimension label
    Rectangle {
        visible: root.regionWidth > 60 && root.regionHeight > 20
        anchors {
            top: selectionBorder.bottom
            horizontalCenter: selectionBorder.horizontalCenter
            topMargin: 8
        }
        radius: Theme.radiusSmall
        color: Theme.alpha(Theme.colLayer0, 0.9)
        width: dimensionText.width + 12
        height: dimensionText.height + 6

        Text {
            id: dimensionText
            anchors.centerIn: parent
            color: Theme.textColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            text: `${Math.round(root.regionWidth)} × ${Math.round(root.regionHeight)}`
        }
    }

    // Crosshair - vertical
    Rectangle {
        visible: root.regionWidth === 0
        x: root.mouseX
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        width: 1
        color: Theme.alpha(root.selectionColor, 0.4)
    }

    // Crosshair - horizontal
    Rectangle {
        visible: root.regionHeight === 0
        y: root.mouseY
        anchors {
            left: parent.left
            right: parent.right
        }
        height: 1
        color: Theme.alpha(root.selectionColor, 0.4)
    }
}
