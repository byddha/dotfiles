import QtQuick
import Quickshell
import "../../Config"
import "../../Services"
import "../../Components"

// An app's real icon from its .desktop entry; a generic window glyph when it has none
Item {
    id: root

    property string appClass: ""
    property int size: BarLayout.appIconSize
    // Rasterized at the size it is drawn on this screen, so it is never scaled down (and blurred)
    readonly property real scale: Compositor.monitorFor(QsWindow.window?.screen)?.scale ?? 1

    implicitWidth: size
    implicitHeight: size

    Image {
        id: image

        anchors.fill: parent
        source: AppIcons.iconSourceFor(root.appClass)
        sourceSize.width: Math.ceil(root.size * root.scale)
        sourceSize.height: Math.ceil(root.size * root.scale)
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: status === Image.Ready
    }

    Icon {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        size: root.size
        text: Lucide.appWindow
        color: Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
    }
}
