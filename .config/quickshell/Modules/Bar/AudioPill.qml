import QtQuick
import "../../Config"

// Icon + percentage pill shared by the volume and mic buttons.
BarPill {
    id: root

    property string icon
    property int iconPixelSize: BarStyle.iconSize
    property bool muted
    property real level

    signal toggleMute
    signal increase
    signal decrease

    width: contentRow.implicitWidth + BarStyle.spacing * 2
    cursorShape: Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            Settings.sidebarSelectedTab = 0;
            Settings.sidebarVisible = true;
        } else if (mouse.button === Qt.RightButton) {
            root.toggleMute();
        }
    }

    Connections {
        target: root.mouseArea

        function onWheel(wheel) {
            if (wheel.angleDelta.y > 0)
                root.increase();
            else
                root.decrease();
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2
        height: parent.height

        Text {
            text: root.icon
            font.family: BarStyle.iconFont
            font.pixelSize: root.iconPixelSize
            color: root.muted ? BarStyle.iconColorMuted : Theme.primary
            height: parent.height
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: Math.round(root.level * 100) + "%"
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: root.muted ? BarStyle.textSecondaryColor : BarStyle.textColor
            height: parent.height
            verticalAlignment: Text.AlignVCenter
        }
    }
}
