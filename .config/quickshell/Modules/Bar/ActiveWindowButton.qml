import QtQuick
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components"

BarItem {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string appClass: toplevel?.appId ?? ""

    visible: toplevel !== null
    iconOnly: !vertical && level >= 2
    tooltipTitle: toplevel?.title ?? ""

    function lengthAt(level) {
        return vertical ? padded(BarLayout.appIconSize) : level >= 2 ? BarLayout.itemSize : padded(BarLayout.appIconSize + BarLayout.itemGap + name.implicitWidth);
    }

    BarAppIcon {
        appClass: root.appClass
    }
    StyledText {
        id: name

        visible: !root.vertical && root.level < 2
        text: AppIcons.getDisplayName(root.appClass, root.toplevel?.title ?? "", "")
    }
}
