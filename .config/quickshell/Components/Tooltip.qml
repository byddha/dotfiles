import QtQuick
import "../Config"

Window {
    id: tooltip

    property Item target: null
    property string text: ""
    property bool pending: false

    flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: Theme.cardSurface
    visible: false

    width: tooltipText.width + Theme.spacingBase * 2
    height: tooltipText.height + Theme.spacingBase * 2

    function show() {
        if (!target || text === "")
            return;
        pending = true;
        showTimer.restart();
    }

    function hide() {
        pending = false;
        showTimer.stop();
        visible = false;
    }

    function _showNow() {
        if (!pending)
            return;
        var pos = target.mapToGlobal(0, target.height);
        x = pos.x - width / 2 + target.width / 2;
        y = pos.y + Theme.spacingBase / 2;
        visible = true;
    }

    Timer {
        id: showTimer
        interval: 500
        onTriggered: tooltip._showNow()
    }

    StyledText {
        id: tooltipText
        anchors.centerIn: parent
        text: tooltip.text
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Normal
    }
}
