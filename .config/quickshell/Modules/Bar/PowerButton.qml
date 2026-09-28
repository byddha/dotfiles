import QtQuick
import "../../Services"

BarItem {
    id: root

    property PowerMenu menu: PowerMenu {}

    iconOnly: true
    highlighted: menu.visible
    tooltipTitle: menu.visible ? "" : "Power"

    onClicked: mouse => {
        if (mouse.button !== Qt.LeftButton)
            return;
        if (menu.visible)
            menu.hidePanel();
        else
            menu.openFrom(root);
    }

    BarIcon {
        text: Lucide.power
    }
}
