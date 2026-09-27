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
}
