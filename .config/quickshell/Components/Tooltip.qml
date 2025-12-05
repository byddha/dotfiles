import QtQuick
import "../Config"

Window {
    id: tooltip

    property Item target: null
    property string text: ""
    property int delay: 500
    property bool isVisible: false

    flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: Theme.surface
    visible: false

    width: tooltipText.width + Theme.spacingBase * 2
    height: tooltipText.height + Theme.spacingBase * 2

    function show() {
        if (!target || text === "")
            return;
        isVisible = true;
        if (delay > 0) {
            showTimer.restart();
        } else {
            _showNow();
        }
    }

    function hide() {
        isVisible = false;
        showTimer.stop();
        visible = false;
    }

    function _showNow() {
        if (!isVisible)
            return;
        var pos = target.mapToGlobal(0, target.height);
        x = pos.x - width / 2 + target.width / 2;
        y = pos.y + Theme.spacingBase / 2;
        visible = true;
    }

    Timer {
        id: showTimer
        interval: tooltip.delay
        onTriggered: tooltip._showNow()
    }

    Text {
        id: tooltipText
        anchors.centerIn: parent
        text: tooltip.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.textColor
    }
}
