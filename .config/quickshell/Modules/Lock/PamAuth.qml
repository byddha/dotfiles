import QtQuick
import Quickshell
import Quickshell.Services.Pam
import "../../Utils"

// The lock's auth: the user's password through PAM, with the shell's own config (assets/pam.d)
Item {
    id: root

    property bool busy: false
    property string message: ""
    property bool error: false
    // PAM's info lines (e.g. pam_faillock's lockout notice), shown instead of a generic error
    property var info: []
    property string password: ""

    signal failed
    signal succeeded

    function submit(password) {
        if (busy || password === "")
            return;
        root.password = password;
        info = [];
        error = false;
        message = "";
        busy = true;
        if (!pam.start()) {
            Logger.error("Lock: PAM did not start");
            fail("Authentication error");
        }
    }

    function fail(text) {
        busy = false;
        password = "";
        error = true;
        message = text;
        failed();
    }

    // A PAM module that never answers would leave the field read-only for good
    Timer {
        interval: 15000
        running: root.busy
        onTriggered: {
            pam.abort();
            Logger.warn("Lock: PAM did not answer");
            root.fail("Authentication timed out");
        }
    }

    PamContext {
        id: pam

        config: "lockscreen"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"
        user: Quickshell.env("USER")

        // Here, not on messageChanged: that comes before responseRequired is set, so a prompt would
        // read as an info line. Each message comes here, also a prompt like the one before it.
        onPamMessage: {
            if (!responseRequired) {
                if (message !== "")
                    root.info = root.info.concat([message]);
            } else if (responseVisible || root.password === "") {
                // Only the password is known here: a second or a shown question cannot be answered
                pam.abort();
                root.fail("Authentication error");
            } else {
                respond(root.password);
                root.password = "";
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.busy = false;
                root.password = "";
                root.succeeded();
                return;
            }
            if (!root.busy)
                return;
            Logger.warn("Lock: PAM auth failed:", result);
            root.fail(root.info.length > 0 ? root.info.join("\n") : result === PamResult.MaxTries ? "Too many attempts" : result === PamResult.Error ? "Authentication error" : "Incorrect password");
        }
        onError: error => {
            Logger.error("Lock: PAM error:", error);
            root.fail("Authentication error");
        }
    }
}
