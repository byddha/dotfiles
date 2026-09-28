import QtQuick
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components"

/**
 * Tray - The tray items in the bar, or, when the bar is short of room (level 2, or 1 on a
 * vertical bar), one chevron that opens them in a popout.
 */
Item {
    id: root

    property int level: 0
    readonly property bool folded: items.count > 1 && level >= (BarLayout.vertical ? 1 : 2)

    property TrayMenu menu: TrayMenu {}
    property BarPopout overflow: BarPopout {
        WlrLayershell.namespace: "bidshell:tray-overflow"
        padding: 6

        TrayItems {
            anchors.fill: parent
            menu: root.menu
            inPopout: true
        }
    }

    function lengthAt(level) {
        const foldedThen = items.count > 1 && level >= (BarLayout.vertical ? 1 : 2);
        if (foldedThen)
            return BarLayout.itemSize;
        return items.count * BarLayout.itemSize + items.spacing * Math.max(0, items.count - 1);
    }

    visible: items.count > 0
    implicitWidth: folded ? chevron.implicitWidth : items.implicitWidth
    implicitHeight: folded ? chevron.implicitHeight : items.implicitHeight

    onFoldedChanged: if (!folded)
        overflow.hidePanel()

    TrayItems {
        id: items

        visible: !root.folded
        menu: root.menu
    }

    BarItem {
        id: chevron

        visible: root.folded
        iconOnly: true
        highlighted: root.overflow.visible
        tooltipTitle: root.overflow.visible ? "" : `${items.count} tray apps`

        onClicked: mouse => {
            if (mouse.button !== Qt.LeftButton)
                return;
            if (root.overflow.visible)
                root.overflow.hidePanel();
            else
                root.overflow.openFrom(chevron);
        }

        Icon {
            text: {
                switch (BarLayout.edge) {
                case "bottom":
                    return Lucide.chevronUp;
                case "left":
                    return Lucide.chevronRight;
                case "right":
                    return Lucide.chevronLeft;
                default:
                    return Lucide.chevronDown;
                }
            }
        }
    }
}
