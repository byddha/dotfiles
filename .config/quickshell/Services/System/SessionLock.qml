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
        authenticating = true;
        pam.start();
    }

    PamContext {
        id: pam
        config: "lockscreen"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"
        user: Quickshell.env("USER")

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
            if (result === PamResult.MaxTries)
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
