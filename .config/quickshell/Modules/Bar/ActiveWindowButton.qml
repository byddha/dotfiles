import QtQuick
import Quickshell.Wayland
import "../../Config"
import "../../Services"

BarItem {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string appClass: toplevel?.appId ?? ""

    visible: toplevel !== null
    tooltipTitle: toplevel?.title ?? ""

    BarAppIcon {
        appClass: root.appClass
    }
    BarText {
        visible: !root.vertical
        text: AppIcons.getDisplayName(root.appClass, root.toplevel?.title ?? "", "")
    }
}
