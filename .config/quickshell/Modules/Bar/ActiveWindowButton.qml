import QtQuick
import Quickshell.Wayland
import "../../Config"
import "../../Services"

BarItem {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string appClass: toplevel?.appId ?? ""

    visible: toplevel !== null
    iconOnly: !vertical && level >= 2
    tooltipTitle: toplevel?.title ?? ""

    function lengthAt(level) {
        return vertical ? padded(16) : level >= 2 ? BarLayout.itemSize : padded(16 + 6 + name.implicitWidth);
    }

    BarAppIcon {
        appClass: root.appClass
    }
    BarText {
        id: name

        visible: !root.vertical && root.level < 2
        text: AppIcons.getDisplayName(root.appClass, root.toplevel?.title ?? "", "")
    }
}
