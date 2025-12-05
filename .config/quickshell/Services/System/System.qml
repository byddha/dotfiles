// System Service - System information and utilities
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: system

    property string hostname: "localhost"
    property string username: "user"
    property string osName: "Linux"

    property string currentTime: Qt.formatTime(new Date(), "hh:mm")
    property string currentDate: Qt.formatDate(new Date(), "yyyy-MM-dd")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            currentTime = Qt.formatTime(new Date(), "hh:mm");
            currentDate = Qt.formatDate(new Date(), "yyyy-MM-dd");
        }
    }

    function lock() {
        Logger.info("Locking session...");
    }

    function logout() {
        Logger.info("Logging out...");
    }

    function shutdown() {
        Logger.info("Shutting down...");
    }

    function reboot() {
        Logger.info("Rebooting...");
    }

    function suspend() {
        Logger.info("Suspending...");
    }
}
