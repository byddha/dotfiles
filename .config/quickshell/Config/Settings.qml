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
    // Set by the idle daemon while the monitors are off: video wallpapers stop decoding
    property bool wallpaperPaused: false

    // For bar buttons: open the sidebar on their tab, or close it when that tab is already open.
    // The sidebar leaves the bar free, so a second click on the button reaches it and closes the sidebar.
    function toggleSidebarTab(tab) {
        if (sidebarVisible && sidebarSelectedTab === tab) {
            sidebarVisible = false;
            return;
        }
        sidebarSelectedTab = tab;
        sidebarVisible = true;
    }
}
