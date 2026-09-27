pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pam
import "../../Utils"

Singleton {
    id: root

    property bool locked: false
    property string password: ""
    property bool authenticating: false
    property string errorMessage: ""
    // PAM info lines (e.g. pam_faillock lockout notices), shown instead of a generic error.
    property var _pamInfo: []

    function lock() {
        password = "";
        errorMessage = "";
        locked = true;
    }

    function unlock() {
        password = "";
        errorMessage = "";
        locked = false;
    }

    function tryUnlock() {
        if (authenticating || password.length === 0)
            return;
        errorMessage = "";
        _pamInfo = [];
        authenticating = true;
        pam.start();
    }

    // A PAM module that never answers would leave the field disabled forever (as in DMS).
    Timer {
        interval: 15000
        running: root.authenticating
        onTriggered: {
            pam.abort();
            root.authenticating = false;
            root.password = "";
            root.errorMessage = "Authentication timed out";
            Logger.warn("PAM auth timed out");
        }
    }

    PamContext {
        id: pam
        config: "lockscreen"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"
        user: Quickshell.env("USER")

        onMessageChanged: {
            if (message.length > 0 && !responseRequired)
                root._pamInfo = root._pamInfo.concat([message]);
        }

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root.password);
        }

        onCompleted: result => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                root.unlock();
                return;
            }
            root.password = "";
            if (root._pamInfo.length > 0)
                root.errorMessage = root._pamInfo.join("\n");
            else if (result === PamResult.MaxTries)
                root.errorMessage = "Too many attempts";
            else if (result === PamResult.Error)
                root.errorMessage = "Authentication error";
            else
                root.errorMessage = "Incorrect password";
            Logger.warn("PAM auth failed:", result);
        }

        onError: err => {
            root.authenticating = false;
            root.errorMessage = "PAM error: " + err;
            Logger.error("PAM error:", err);
        }
    }
}
