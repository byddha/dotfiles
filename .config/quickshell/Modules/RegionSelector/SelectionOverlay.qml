import QtQuick
import "../../Config"
import "../../Components"

Item {
    id: root

    required property real regionX
    required property real regionY
    required property real regionWidth
    required property real regionHeight
    required property real mouseX
    required property real mouseY
    required property real monitorScale
    property bool showHandles: false

    // Dims everything outside the selection
    ShaderEffect {
        anchors.fill: parent

        // Properties must match shader uniform order (std140 layout)
        property real overlayOpacity: 0.5
        property color overlayColor: "black"
        property vector4d selection: Qt.vector4d(root.regionX, root.regionY, root.regionWidth, root.regionHeight)
        property vector4d resolutionAndRadius: Qt.vector4d(root.width, root.height, 0, 0)  // No corner rounding for fullscreen
        // No cutouts for selection overlay
        property vector4d cutout1: Qt.vector4d(0, 0, 0, 0)
        property vector4d cutout2: Qt.vector4d(0, 0, 0, 0)
        property vector4d cutout3: Qt.vector4d(0, 0, 0, 0)
        property vector4d cutout4: Qt.vector4d(0, 0, 0, 0)

        fragmentShader: "shaders/selection_overlay.frag.qsb"
    }

    // Border drawn outside the selection so it never covers the content: a white line with a
    // faint dark line around it, readable on light and dark content
    Rectangle {
        id: selectionBorder
        x: root.regionX - 2
        y: root.regionY - 2
        width: root.regionWidth + 4
        height: root.regionHeight + 4
        color: "transparent"
        border.color: Qt.rgba(0, 0, 0, 0.35)
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.95)
            border.width: 1
        }
    }

    // Resize handles on the corners and edge midpoints (the same 8 spots getHandleAt accepts)
    Repeater {
        model: root.showHandles ? [[0, 0], [0.5, 0], [1, 0], [0, 0.5], [1, 0.5], [0, 1], [0.5, 1], [1, 1]] : []

        Rectangle {
            required property var modelData
            readonly property real size: 10
            x: root.regionX - 1.5 + (root.regionWidth + 3) * modelData[0] - size / 2
            y: root.regionY - 1.5 + (root.regionHeight + 3) * modelData[1] - size / 2
            width: size
            height: size
            radius: size / 2
            color: "white"
            border.color: Qt.rgba(0, 0, 0, 0.35)
            border.width: 1
        }
    }

    // Size of the saved image in native pixels, above the top-left corner (inside when there is no room)
    Rectangle {
        visible: root.regionWidth > 40 && root.regionHeight > 20
        x: root.regionX - 2
        y: root.regionY - height - 8 >= 0 ? root.regionY - height - 8 : root.regionY + 8
        radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.7)
        width: dimensionText.implicitWidth + 20
        height: dimensionText.implicitHeight + 8

        StyledText {
            id: dimensionText
            anchors.centerIn: parent
            color: "white"
            // Edges rounded one by one, like the capture in _grabRegionToFile
            text: `${Math.round((root.regionX + root.regionWidth) * root.monitorScale) - Math.round(root.regionX * root.monitorScale)} × ${Math.round((root.regionY + root.regionHeight) * root.monitorScale) - Math.round(root.regionY * root.monitorScale)}`
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
        color: Qt.rgba(1, 1, 1, 0.3)
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
        color: Qt.rgba(1, 1, 1, 0.3)
    }
}
