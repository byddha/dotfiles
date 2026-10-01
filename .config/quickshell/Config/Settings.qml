pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: settings

    property bool sidebarVisible: false
    property int sidebarSelectedTab: 0  // 0 = Volume Mixer, 1 = Notifications
    property bool gameLauncherVisible: false
    property bool regionSelectorVisible: false
    property bool shutdownReminderVisible: false

    // For bar buttons: open the sidebar on their tab, or close it when that tab is already open.
    // A toggle, not an open, because a click right after opening still lands on the button (the
    // sidebar's click-outside surface is not up yet) and must close it as well.
    function toggleSidebarTab(tab) {
        if (sidebarVisible && sidebarSelectedTab === tab) {
            sidebarVisible = false;
            return;
        }
        sidebarSelectedTab = tab;
        sidebarVisible = true;
    }
}
