import QtQuick
import "../../Services"
import "../../Components"

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

    Icon {
        text: Lucide.power
    }
}
