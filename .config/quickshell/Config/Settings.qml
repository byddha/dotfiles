pragma Singleton

import QtQuick
import Quickshell
import "../Services"
import "../Utils"

Singleton {
    id: settings

    function init() {
        Logger.info("Settings initialized");
    }

    property bool launcherVisible: false
    property bool notificationsVisible: true
    property bool barVisible: true
    property bool hyprWhichKeyVisible: false
    property bool overviewVisible: false
    property bool sidebarVisible: false
    property int sidebarSelectedTab: 0  // 0 = Volume Mixer, 1 = Notifications
    property bool osdVisible: false
    property bool calendarPanelVisible: false

    onSidebarVisibleChanged: Logger.debug("sidebarVisible →", sidebarVisible)
    onOverviewVisibleChanged: Logger.debug("overviewVisible →", overviewVisible)
    onCalendarPanelVisibleChanged: Logger.debug("calendarPanelVisible →", calendarPanelVisible)
    onHyprWhichKeyVisibleChanged: Logger.debug("hyprWhichKeyVisible →", hyprWhichKeyVisible)
    onOsdVisibleChanged: Logger.debug("osdVisible →", osdVisible)
}
