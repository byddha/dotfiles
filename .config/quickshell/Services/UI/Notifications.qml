pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../../Config"
import "../../Utils"

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
            "urgency": notif.urgency
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
                    "urgency": notif.urgency
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
