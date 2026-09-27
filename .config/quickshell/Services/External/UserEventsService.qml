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
        } else {
            delete events[key];
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
            } catch (e) {
                Logger.warn("Failed to parse user events:", e);
                root.events = {};
            }
        }

        onLoadFailed: function (error) {
            root.events = {};
        }
    }
}
