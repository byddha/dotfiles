import QtQuick
import "../../Config"
import "../../Services"

// An app's real icon from its .desktop entry; a generic window glyph when it has none
Item {
    id: root

    property string appClass: ""
    property int size: 16

    implicitWidth: size
    implicitHeight: size

    Image {
        id: image

        anchors.fill: parent
        source: AppIcons.iconSourceFor(root.appClass)
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: status === Image.Ready
    }

    BarIcon {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        size: root.size
        text: Lucide.appWindow
        color: Theme.alpha(Theme.textSecondary, 0.66)
    }
}
