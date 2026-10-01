import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../Config"
import "../../Services"
import "../../Components"

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
    radius: Theme.radiusWindow
    clip: true  // keeps the class label inside windows smaller than it
    visible: opacity > 0

    function getCutout(index) {
        if (index < cutouts.length && cutouts[index]) {
            const c = cutouts[index];
            return Qt.vector4d(c.x, c.y, c.width, c.height);
        }
        return Qt.vector4d(0, 0, 0, 0);
    }

    // Dims the window (rounded corners, floating windows above it cut out)
    ShaderEffect {
        anchors.fill: parent
        visible: !root.targeted

        property real overlayOpacity: 0.5
        property color overlayColor: "black"
        property vector4d selection: Qt.vector4d(0, 0, 0, 0)
        property vector4d resolutionAndRadius: Qt.vector4d(root.width, root.height, Theme.radiusWindow, 0)
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
        color: Theme.hostSurface
        border.color: Theme.primary
        border.width: 2
        width: labelRow.width + 24
        height: labelRow.height + 16

        RowLayout {
            id: labelRow
            anchors.centerIn: parent
            spacing: 8

            IconImage {
                readonly property string iconSource: AppIcons.iconSourceFor(root.clientDimensions.class)

                visible: iconSource !== ""
                implicitSize: 24
                source: iconSource
            }

            StyledText {
                text: AppIcons.getDisplayName(root.clientDimensions.class, root.clientDimensions.title, "") || root.clientDimensions.class || "Window"
                font.pixelSize: Theme.fontSizeTitle
            }
        }
    }
}
