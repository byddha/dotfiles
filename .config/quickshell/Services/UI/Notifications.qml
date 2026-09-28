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
        property int seq: 0
        property var ruleSet: ({})
        property bool isTransient: ruleSet && ruleSet.hasOwnProperty("transient") ? !!ruleSet.transient : (notification?.transient ?? false)
        property string appIcon: notification?.appIcon ?? ""
        // DMS: an empty app name falls back to the desktop entry's name, then "app".
        property string appName: {
            if (!notification)
                return "";
            if (notification.appName)
                return notification.appName;
            const entry = notification.desktopEntry ? DesktopEntries.heuristicLookup(notification.desktopEntry) : null;
            return entry?.name?.toLowerCase() || "app";
        }
        property string body: root.messageBody(notification?.body ?? "", notification?.appName ?? "")
        property string image: notification?.image ?? ""
        property string summary: notification?.summary ?? ""
        property double time
        // NotificationUrgency value (Low 0, Normal 1, Critical 2), as in DMS.
        property int urgency: notification?.urgency ?? NotificationUrgency.Normal
        property string desktopEntry: notification?.desktopEntry ?? ""
        property var rawHints: notification?.hints ?? ({})

        // DMS NotifWrapper timer: the app's expire timeout wins, else the urgency default; 0 never expires.
        readonly property Timer timer: Timer {
            interval: {
                const appTimeout = wrapper.notification?.expireTimeout ?? -1;
                if (appTimeout >= 0)
                    return Math.round(appTimeout);
                return wrapper.urgency === NotificationUrgency.Critical ? root.timeoutCritical : root.timeoutNormal;
            }
            repeat: false
            running: false
            onTriggered: {
                if (interval > 0)
                    root.timeoutNotification(wrapper.notificationId);
            }
        }

        onNotificationChanged: {
            if (notification === null) {
                root.discardNotification(notificationId);
            }
        }
    }

    // DMS defaults (notificationTimeoutLow/Normal/Critical).
    readonly property int timeoutNormal: 5000
    readonly property int timeoutCritical: 0

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

    // --- Icons and images, following DMS NotificationService ---

    function _iconFromImage(image) {
        return (image || "").startsWith("image://icon/") ? image.substring(13) : "";
    }

    function _isPathOrUrl(value) {
        return /^(file|https?):\/\//.test(value) || value.startsWith("/");
    }

    function _toUrl(value) {
        return value.startsWith("/") ? "file://" + value : value;
    }

    // Apps like kitty send their bundled logo path; the themed icon wins when its basename resolves.
    function _themedAppIcon(appIcon) {
        if (/^https?:\/\//.test(appIcon))
            return "";
        const path = appIcon.startsWith("file://") ? appIcon.substring(7) : appIcon;
        if (!path.startsWith("/"))
            return "";
        const file = path.substring(path.lastIndexOf("/") + 1);
        const dot = file.lastIndexOf(".");
        const base = dot > 0 ? file.substring(0, dot) : file;
        return base && Quickshell.iconPath(base, true) ? base : "";
    }

    // A real content image (image-data, image-path file, qsimage), not an icon name passed as image.
    function contentImageSource(notif) {
        const image = notif?.image || "";
        if (!image)
            return "";
        const fromImage = _iconFromImage(image);
        if (image.startsWith("image://icon/"))
            return fromImage.startsWith("/") ? "file://" + fromImage : "";
        return image;
    }

    // Icon for the app icon box: explicit path, themed icon name, or the desktop entry's icon.
    function appIconSource(notif) {
        const entry = notif?.desktopEntry ? DesktopEntries.heuristicLookup(notif.desktopEntry) : null;
        const override = AppIcons.overrideFor(entry?.id ?? "");
        if (override)
            return override;
        const appIcon = notif?.appIcon || entry?.icon || "";
        const themed = _themedAppIcon(appIcon);
        if (themed)
            return Quickshell.iconPath(themed, true);
        if (appIcon && _isPathOrUrl(appIcon))
            return _toUrl(appIcon);
        const fromImage = _iconFromImage(notif?.image || "");
        const name = appIcon || (fromImage.startsWith("/") ? "" : fromImage);
        return name ? Quickshell.iconPath(name, true) : "";
    }

    // Storage path
    readonly property string cacheDir: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] + "/bidshell"
    readonly property string filePath: cacheDir + "/notifications.json"

    // State
    property bool dnd: false  // Do Not Disturb mode
    property list<Notif> list: []
    property var popupList: list.filter(notif => notif.popup)
    property bool popupInhibited: (Settings.sidebarVisible ?? false) || dnd

    // --- Popup limit and queue, ported from DMS NotificationService (_enqueuePopup, processQueue, addGate) ---
    readonly property int maxVisibleNotifications: 4
    readonly property int maxQueueSize: 32
    property var popupQueue: []
    property bool addGateBusy: false
    property int seqCounter: 0

    onPopupListChanged: processQueue()
    onPopupInhibitedChanged: {
        if (!popupInhibited)
            return;
        const dropped = popupQueue;
        popupQueue = [];
        dropped.forEach(n => timeoutNotification(n.notificationId));
    }

    function enqueuePopup(notif) {
        if (popupQueue.length >= maxQueueSize) {
            const critical = n => n.urgency === NotificationUrgency.Critical;
            let idx = popupQueue.findIndex(n => n.appName === notif.appName && !critical(n));
            if (idx === -1)
                idx = popupQueue.findIndex(n => !critical(n));
            const victim = popupQueue[Math.max(0, idx)];
            popupQueue = popupQueue.filter(n => n !== victim);
            timeoutNotification(victim.notificationId);
        }
        popupQueue = [...popupQueue, notif];
        processQueue();
    }

    function processQueue() {
        if (addGateBusy || popupInhibited || popupQueue.length === 0)
            return;
        // Set before evicting: the eviction changes popupList, which re-enters processQueue.
        addGateBusy = true;
        const next = popupQueue[0];
        popupQueue = popupQueue.slice(1);
        next.seq = ++seqCounter;
        const active = popupList;
        if (active.length >= maxVisibleNotifications) {
            // Evict the oldest popup whose timer runs (not hovered), else the oldest overall.
            const unhovered = active.filter(n => n.timer.running);
            const pool = unhovered.length > 0 ? unhovered : active;
            const evicted = pool.reduce((min, n) => n.seq < min.seq ? n : min, pool[0]);
            timeoutNotification(evicted.notificationId);
        }
        next.popup = true;
        if (next.timer.interval > 0)
            next.timer.start();
        addGate.restart();
    }

    Timer {
        id: addGate
        interval: 80
        onTriggered: {
            root.addGateBusy = false;
            root.processQueue();
        }
    }

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
            const ruleSet = root._computeRuleSet(notification);
            const isTransient = ruleSet.hasOwnProperty("transient") ? !!ruleSet.transient : notification.transient;

            // Transient notifications must never persist. If we can't show the popup, drop the notification entirely.
            if (isTransient && root.popupInhibited) {
                Logger.info(`Dropped transient notification (popup inhibited): ${notification.summary}`);
                notification.dismiss();
                return;
            }

            notification.tracked = true;
            const newNotifObject = notifComponent.createObject(root, {
                "notificationId": notification.id + root.idOffset,
                "notification": notification,
                "ruleSet": ruleSet,
                "time": Date.now()
            });
            root.list = [...root.list, newNotifObject];

            if (!root.popupInhibited)
                root.enqueuePopup(newNotifObject);
            Logger.info(`New notification from ${newNotifObject.appName}: ${newNotifObject.summary}`);
            notifFileView.setText(stringifyList(root.list));
        }
    }

    function discardNotification(id) {
        Logger.info(`Discarding notification with ID: ${id}`);
        root.popupQueue = root.popupQueue.filter(n => n.notificationId !== id);
        const index = root.list.findIndex(notif => notif.notificationId === id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id + root.idOffset === id);
        if (index !== -1) {
            root.list[index].timer.stop();
            root.list.splice(index, 1);
            notifFileView.setText(stringifyList(root.list));
            triggerListChange();
        }
        if (notifServerIndex !== -1) {
            notifServer.trackedNotifications.values[notifServerIndex].dismiss();
        }
    }

    function discardAllNotifications() {
        root.popupQueue = [];
        root.list = [];
        triggerListChange();
        notifFileView.setText(stringifyList(root.list));
        notifServer.trackedNotifications.values.forEach(notif => {
            notif.dismiss();
        });
        Logger.info("All notifications discarded");
    }

    // Popup ended (timeout or close button): transient notifications go away entirely, the rest stay in history.
    function timeoutNotification(id) {
        const notif = root.list.find(n => n.notificationId === id);
        if (!notif)
            return;
        notif.timer.stop();
        Logger.info(`Notification popup ended for ID: ${id}, transient: ${notif.isTransient}`);
        if (notif.isTransient) {
            root.discardNotification(id);
            return;
        }
        notif.popup = false;
        autoClearDebounce.restart();
    }

    function attemptInvokeAction(id, notifIdentifier) {
        Logger.info(`Attempting to invoke action with identifier: ${notifIdentifier} for notification ID: ${id}`);
        // Self-dispatched actions: "open:<url-encoded-url>" opens the URL directly, independent of
        // the original sender. Works from popup, history, and after restart (see onLoaded below).
        // URL is encoded so "=" in query strings doesn't collide with notify-send's -A parsing.
        if (typeof notifIdentifier === "string" && notifIdentifier.startsWith("open:")) {
            Qt.openUrlExternally(decodeURIComponent(notifIdentifier.slice(5)));
            root.discardNotification(id);
            return;
        }
        const serverNotif = notifServer.trackedNotifications.values.find(notif => notif.id + root.idOffset === id);
        const action = serverNotif?.actions.find(action => action.identifier === notifIdentifier);
        if (!action) {
            Logger.warn(`Action ${notifIdentifier} not found for notification ${id}`);
            root.discardNotification(id);
            return;
        }
        // DMS: resident notifications survive their actions, so only the popup closes.
        const resident = serverNotif.resident;
        action.invoke();
        if (resident)
            root.timeoutNotification(id);
        else
            root.discardNotification(id);
    }

    function triggerListChange() {
        root.list = root.list.slice(0);
    }

    // --- Auto-clear on focus ---

    function _matchesPattern(value, pattern) {
        if (pattern === undefined || pattern === null)
            return true;
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
        if (!obj)
            return undefined;
        // hints.* digs into the raw hints dict stored on the wrapper
        if (path.indexOf("hints.") === 0) {
            const hints = obj.rawHints ?? {};
            return hints[path.slice(6)];
        }
        // Rules match urgency by name ("low" / "normal" / "critical"), as documented in Config.qml.
        if (path === "urgency" && obj.urgency !== undefined)
            return ["low", "normal", "critical"][obj.urgency];
        // Direct top-level key first (handles names containing dots like "desktop-entry")
        if (obj[path] !== undefined)
            return obj[path];
        // Dotted path traversal (e.g. "workspace.id")
        const parts = path.split(".");
        let cur = obj;
        for (const part of parts) {
            if (cur === undefined || cur === null)
                return undefined;
            cur = cur[part];
        }
        return cur;
    }

    // Chromium-based browsers put the site's link before a web app's message ("<a href=...>site</a>\n\n<message>").
    // Cards, the history search, copy and the saved history get the message; rules still see the whole body,
    // where the site is what tells two web apps apart.
    function messageBody(body, appName) {
        const browsers = ["brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"];
        const app = appName.toLowerCase();
        const paragraphs = body.split("\n\n");
        if (paragraphs.length > 1 && /^<a [^>]*>[^<]*<\/a>$/.test(paragraphs[0]) && browsers.some(browser => app.includes(browser)))
            return paragraphs.slice(1).join("\n\n");
        return body;
    }

    function _notifView(notification) {
        return {
            "appName": notification.appName ?? "",
            "desktopEntry": notification.hints?.["desktop-entry"] ?? "",
            "summary": notification.summary ?? "",
            "body": notification.body ?? "",
            "urgency": notification.urgency,
            "rawHints": notification.hints ?? {}
        };
    }

    function _computeRuleSet(notification) {
        const rules = Config.options?.notifications?.rules ?? [];
        if (!rules.length)
            return {};
        const view = _notifView(notification);
        const merged = {};
        for (const rule of rules) {
            if (_blockMatches(view, rule.match))
                Object.assign(merged, rule.set ?? {});
        }
        return merged;
    }

    function _blockMatches(obj, block) {
        if (!block)
            return true;
        for (const key in block) {
            const value = _resolveField(obj, key);
            if (!_matchesPattern(value, block[key]))
                return false;
        }
        return true;
    }

    // IPC data is not refreshed on title changes, so class and title come live from ToplevelManager.
    function _focusedWindow() {
        const ipc = (Compositor.windowList ?? []).find(w => w.focusHistoryID === 0) ?? {};
        return Object.assign({}, ipc, {
            class: Compositor.activeWindowClass,
            title: Compositor.activeWindow
        });
    }

    function _runAutoClear() {
        const rules = Config.options?.notifications?.autoClearOnFocus ?? [];
        if (!rules.length || !root.list.length)
            return;
        const win = _focusedWindow();
        if (!win)
            return;
        for (const rule of rules) {
            if (!_blockMatches(win, rule.focus))
                continue;
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
        function onActiveWindowClassChanged() {
            autoClearDebounce.restart();
        }
        function onActiveWindowChanged() {
            autoClearDebounce.restart();
        }
        function onWindowDataUpdated() {
            autoClearDebounce.restart();
        }
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
                    // Most actions are meaningless after reload (sender is gone). Preserve only
                    // self-dispatched "open:<url>" actions — those are handled by attemptInvokeAction.
                    "actions": (notif.actions || []).filter(a => typeof a?.identifier === "string" && a.identifier.startsWith("open:")),
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
