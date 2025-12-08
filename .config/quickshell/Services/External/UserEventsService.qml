pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import "../../Utils"

Singleton {
    id: root

    readonly property string cacheDir: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] + "/bidshell"
    readonly property string filePath: cacheDir + "/user_events.json"

    property var events: ({})
    property bool loaded: false

    function init() {
        Logger.info("Service initialized");
    }

    /**
     * Get user event for a specific date
     * @returns Event description or null
     */
    function getEvent(year, month, day) {
        const key = year + "-" + String(month + 1).padStart(2, '0') + "-" + String(day).padStart(2, '0');
        return events[key] || null;
    }

    /**
     * Set or update a user event
     */
    function setEvent(year, month, day, description) {
        const key = year + "-" + String(month + 1).padStart(2, '0') + "-" + String(day).padStart(2, '0');
        if (description && description.trim()) {
            events[key] = description.trim();
            Logger.info("User event set:", key, "=", description.trim());
        } else {
            delete events[key];
            Logger.info("User event deleted:", key);
        }
        eventsChanged();
        save();
    }

    /**
     * Delete a user event
     */
    function deleteEvent(year, month, day) {
        setEvent(year, month, day, null);
    }

    /**
     * Check if a date has a user event
     */
    function hasEvent(year, month, day) {
        return getEvent(year, month, day) !== null;
    }

    function save() {
        fileView.setText(JSON.stringify(events, null, 2));
    }

    FileView {
        id: fileView
        path: root.filePath
        printErrors: false

        onLoaded: {
            try {
                root.events = JSON.parse(fileView.text()) || {};
                Logger.info("Loaded", Object.keys(root.events).length, "user events");
            } catch (e) {
                Logger.warn("Failed to parse user events:", e);
                root.events = {};
            }
            root.loaded = true;
        }

        onLoadFailed: function (error) {
            Logger.info("No user events file, starting fresh");
            root.events = {};
            root.loaded = true;
        }
    }
}
