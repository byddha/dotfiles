pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../../Config"
import "../../Utils"
import ".."

Singleton {
    id: root

    component Notif: QtObject {
        id: wrapper
        required property int notificationId
        property Notification notification
        property list<var> actions: notification?.actions.map(action => ({
                    "identifier": action.identifier,
                    "text": action.text
                })) ?? []
        property bool popup: false
        property bool isTransient: notification?.hints.transient ?? false
        property string appIcon: notification?.appIcon ?? ""
        property string appName: notification?.appName ?? ""
        property string body: notification?.body ?? ""
        property string image: notification?.image ?? ""
        property string summary: notification?.summary ?? ""
        property double time
        property string urgency: notification?.urgency.toString() ?? "normal"
        property string desktopEntry: notification?.hints["desktop-entry"] ?? ""
        property var rawHints: notification?.hints ?? ({})
        property Timer timer

        onNotificationChanged: {
            if (notification === null) {
                root.discardNotification(notificationId);
            }
        }
    }

    function notifToJSON(notif) {
        return {
            "notificationId": notif.notificationId,
            "actions": notif.actions,
            "appIcon": notif.appIcon,
            "appName": notif.appName,
            "body": notif.body,
            "image": notif.image,
            "summary": notif.summary,
            "time": notif.time,
            "urgency": notif.urgency,
            "desktopEntry": notif.desktopEntry
        };
    }

    component NotifTimer: Timer {
        required property int notificationId
        interval: 4000
        running: true
        onTriggered: () => {
            const index = root.list.findIndex(notif => notif.notificationId === notificationId);
            const notifObject = root.list[index];
            Logger.info(`Notification timer triggered for ID: ${notificationId}, transient: ${notifObject?.isTransient}`);
            if (notifObject.isTransient)
                root.discardNotification(notificationId);
            else
                root.timeoutNotification(notificationId);
            destroy();
        }
    }

    // Storage path
    readonly property string cacheDir: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] + "/bidshell"
    readonly property string filePath: cacheDir + "/notifications.json"

    // State
    property bool dnd: false  // Do Not Disturb mode
    property list<Notif> list: []
    property var popupList: list.filter(notif => notif.popup)
    property bool popupInhibited: (Settings.sidebarVisible ?? false) || dnd

    function toggleDnd() {
        dnd = !dnd;
        Logger.info(`DND mode ${dnd ? "enabled" : "disabled"}`);
    }

    // ID offset to avoid collisions with saved notifications
    property int idOffset

    // Components
    Component {
        id: notifComponent
        Notif {}
    }

    Component {
        id: notifTimerComponent
        NotifTimer {}
    }

    function stringifyList(list) {
        return JSON.stringify(list.map(notif => notifToJSON(notif)), null, 2);
    }

    NotificationServer {
        id: notifServer
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: notification => {
            const isTransient = notification.hints?.transient ?? false;

            // Transient notifications must never persist. If we can't show the popup, drop the notification entirely.
            if (isTransient && root.popupInhibited) {
                Logger.info(`Dropped transient notification (popup inhibited): ${notification.summary}`);
                return;
            }

            notification.tracked = true;
            const newNotifObject = notifComponent.createObject(root, {
                "notificationId": notification.id + root.idOffset,
                "notification": notification,
                "time": Date.now()
            });
            root.list = [...root.list, newNotifObject];

            // Popup
            if (!root.popupInhibited) {
                newNotifObject.popup = true;
                if (notification.expireTimeout != 0 || isTransient) {
                    newNotifObject.timer = notifTimerComponent.createObject(root, {
                        "notificationId": newNotifObject.notificationId,
                        "interval": notification.expireTimeout > 0 ? notification.expireTimeout : 7000
                    });
                }
            }
            Logger.info(`New notification from ${newNotifObject.appName}: ${newNotifObject.summary}`);
            notifFileView.setText(stringifyList(root.list));
        }
    }

    function discardNotification(id) {
        Logger.info(`Discarding notification with ID: ${id}`);
        const index = root.list.findIndex(notif => notif.notificationId === id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id + root.idOffset === id);
        if (index !== -1) {
            root.list.splice(index, 1);
            notifFileView.setText(stringifyList(root.list));
            triggerListChange();
        }
        if (notifServerIndex !== -1) {
            notifServer.trackedNotifications.values[notifServerIndex].dismiss();
        }
    }

    function discardAllNotifications() {
        root.list = [];
        triggerListChange();
        notifFileView.setText(stringifyList(root.list));
        notifServer.trackedNotifications.values.forEach(notif => {
            notif.dismiss();
        });
        Logger.info("All notifications discarded");
    }

    function timeoutNotification(id) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        if (root.list[index] != null)
            root.list[index].popup = false;
        autoClearDebounce.restart();
    }

    function attemptInvokeAction(id, notifIdentifier) {
        Logger.info(`Attempting to invoke action with identifier: ${notifIdentifier} for notification ID: ${id}`);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id + root.idOffset === id);
        if (notifServerIndex !== -1) {
            const notifServerNotif = notifServer.trackedNotifications.values[notifServerIndex];
            const action = notifServerNotif.actions.find(action => action.identifier === notifIdentifier);
            action.invoke();
        } else {
            Logger.warn(`Notification not found in server: ${id}`);
        }
        root.discardNotification(id);
    }

    function triggerListChange() {
        root.list = root.list.slice(0);
    }

    // --- Auto-clear on focus ---

    function _matchesPattern(value, pattern) {
        if (pattern === undefined || pattern === null) return true;
        if (Array.isArray(pattern))
            return pattern.some(p => _matchesPattern(value, p));
        const valueStr = (value === undefined || value === null) ? "" : String(value);
        const patternStr = String(pattern);
        // "/regex/flags" → regex; anything else → case-insensitive substring
        if (patternStr.length >= 2 && patternStr[0] === "/") {
            const lastSlash = patternStr.lastIndexOf("/");
            if (lastSlash > 0) {
                try {
                    const re = new RegExp(patternStr.slice(1, lastSlash), patternStr.slice(lastSlash + 1) || "i");
                    return re.test(valueStr);
                } catch (e) {
                    Logger.warn(`Invalid regex in autoClearOnFocus: ${patternStr} (${e})`);
                    return false;
                }
            }
        }
        return valueStr.toLowerCase().includes(patternStr.toLowerCase());
    }

    function _resolveField(obj, path) {
        if (!obj) return undefined;
        // hints.* digs into the raw hints dict stored on the wrapper
        if (path.indexOf("hints.") === 0) {
            const hints = obj.rawHints ?? {};
            return hints[path.slice(6)];
        }
        // Direct top-level key first (handles names containing dots like "desktop-entry")
        if (obj[path] !== undefined) return obj[path];
        // Dotted path traversal (e.g. "workspace.id")
        const parts = path.split(".");
        let cur = obj;
        for (const part of parts) {
            if (cur === undefined || cur === null) return undefined;
            cur = cur[part];
        }
        return cur;
    }

    function _blockMatches(obj, block) {
        if (!block) return true;
        for (const key in block) {
            const value = _resolveField(obj, key);
            if (!_matchesPattern(value, block[key])) return false;
        }
        return true;
    }

    function _focusedWindow() {
        const list = Compositor.windowList ?? [];
        for (const w of list) {
            if (w.focusHistoryID === 0) return w;
        }
        return {
            class: Compositor.activeWindowClass,
            title: Compositor.activeWindow
        };
    }

    function _runAutoClear() {
        const rules = Config.options?.notifications?.autoClearOnFocus ?? [];
        if (!rules.length || !root.list.length) return;
        const win = _focusedWindow();
        if (!win) return;
        for (const rule of rules) {
            if (!_blockMatches(win, rule.focus)) continue;
            const toDiscard = [];
            for (const notif of root.list) {
                // Only touch entries whose popup has already ended — don't interrupt a showing popup.
                if (!notif.popup && _blockMatches(notif, rule.match))
                    toDiscard.push(notif.notificationId);
            }
            for (const id of toDiscard) {
                Logger.info(`Auto-clear (focus=${win.class || "?"}): discarding ${id}`);
                root.discardNotification(id);
            }
        }
    }

    Timer {
        id: autoClearDebounce
        interval: 500
        repeat: false
        onTriggered: root._runAutoClear()
    }

    Connections {
        target: Compositor
        function onActiveWindowClassChanged() { autoClearDebounce.restart() }
        function onWindowDataUpdated() { autoClearDebounce.restart() }
    }

    Component.onCompleted: {
        notifFileView.reload();
    }

    FileView {
        id: notifFileView
        path: root.filePath
        onLoaded: {
            const fileContents = notifFileView.text();
            root.list = JSON.parse(fileContents).map(notif => {
                return notifComponent.createObject(root, {
                    "notificationId": notif.notificationId,
                    "actions": [] // Actions are meaningless if sender is dead
                    ,
                    "appIcon": notif.appIcon,
                    "appName": notif.appName,
                    "body": notif.body,
                    "image": notif.image,
                    "summary": notif.summary,
                    "time": notif.time,
                    "urgency": notif.urgency,
                    "desktopEntry": notif.desktopEntry ?? ""
                });
            });
            // Find largest notificationId
            let maxId = 0;
            root.list.forEach(notif => {
                maxId = Math.max(maxId, notif.notificationId);
            });

            Logger.info("Notification history loaded");
            root.idOffset = maxId;
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                Logger.info("No history file found, creating new file");
                root.list = [];
                notifFileView.setText(stringifyList(root.list));
            } else {
                Logger.error(`Error loading file: ${error}`);
            }
        }
    }
}
