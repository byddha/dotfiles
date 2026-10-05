import QtQuick

// The auth of the design preview: never PAM, where pam_faillock would lock the account after a few
// wrong tries. "test" is right, anything else wrong, each after a short wait as a real check takes.
QtObject {
    id: root

    property bool busy: false
    property string message: ""
    property bool error: false

    signal failed

    function submit(password) {
        if (busy)
            return;
        busy = true;
        error = false;
        message = "";
        check.password = password;
        check.restart();
    }

    // For the preview's IPC: the field's states without typing
    function setState(state) {
        check.stop();
        busy = state === "busy";
        error = state === "error";
        message = state === "error" ? "Incorrect password" : "";
    }

    property Timer check: Timer {
        property string password

        interval: 600
        onTriggered: {
            root.busy = false;
            root.error = password !== "test";
            root.message = root.error ? "Incorrect password" : "Unlocked";
            if (root.error)
                root.failed();
        }
    }
}
