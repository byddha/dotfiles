import QtQuick
import "../../Config"
import "../../Services"
import "../../Components"

BarItem {
    id: root

    readonly property var window: Compositor.activeWindow
    readonly property string appClass: window?.appId ?? ""

    visible: window !== null
    iconOnly: !vertical && level >= 2
    tooltipTitle: window?.title ?? ""

    function lengthAt(level) {
        return vertical ? padded(BarLayout.appIconSize) : level >= 2 ? BarLayout.itemSize : padded(BarLayout.appIconSize + BarLayout.itemGap + name.implicitWidth);
    }

    BarAppIcon {
        appClass: root.appClass
    }
    StyledText {
        id: name

        visible: !root.vertical && root.level < 2
        text: AppIcons.getDisplayName(root.appClass, root.window?.title ?? "", "")
    }
}
