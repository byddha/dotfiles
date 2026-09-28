import QtQuick
import "../../Config"
import "../../Services"

BarPill {
    id: activeWindowTitle

    width: contentRow.implicitWidth + BarStyle.spacing * 2
    cursorShape: Qt.ArrowCursor

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2

        Text {
            text: AppIcons.getIcon(Compositor.activeWindowClass, Compositor.activeWindow)
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.iconSize
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: AppIcons.getDisplayName(Compositor.activeWindowClass, Compositor.activeWindow)
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: BarStyle.textColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
