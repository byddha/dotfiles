import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import "../../Utils"

// The greeter's auth: logs `user` in through greetd, then starts `session`
Item {
    id: root

    property string user: ""
    // {id, name, command, env}, from Sessions
    property var session: null
    property bool busy: false
    property string message: ""
    property bool error: false
    // A question greetd asks besides the password (e.g. a one-time code): the field answers it, shown
    // as typed when `echo`
    property string prompt: ""
    property bool echo: false
    property string password: ""
    // greetd's info and error lines of this attempt (e.g. pam_faillock's lockout notice), shown
    // instead of a generic error
    property var info: []

    signal failed
    // Before the session starts and the greeter quits: the time to remember the user and session
    signal launching

    function submit(text) {
        if (busy)
            return;
        if (prompt !== "") {
            prompt = "";
            echo = false;
            busy = true;
            Greetd.respond(text);
            return;
        }
        const name = user.trim();
        if (text === "" || name === "")
            return;
        if (!session) {
            fail("No session to start");
            return;
        }
        if (!Greetd.available) {
            fail("greetd is not running");
            return;
        }
        user = name;
        info = [];
        error = false;
        message = "";
        password = text;
        busy = true;
        Greetd.createSession(name);
    }

    function cancel() {
        if (prompt === "")
            return;
        prompt = "";
        echo = false;
        Greetd.cancelSession();
        settle.restart();
    }

    function fail(text) {
        password = "";
        prompt = "";
        echo = false;
        error = true;
        message = info.length > 0 ? info.join("\n") : text;
        failed();
        settle.restart();
    }

    // Stays busy a moment after a failure: Quickshell cancels the failed session itself and takes
    // greetd's reply to that for the next login's (quickshell #1266), so a new attempt waits for it
    Timer {
        id: settle

        interval: 300
        onTriggered: root.busy = false
    }

    // An attempt greetd never answers would leave the fields read-only for good
    Timer {
        interval: 15000
        running: root.busy && !settle.running
        onTriggered: {
            Logger.warn("Greeter: greetd did not answer");
            Greetd.cancelSession();
            root.fail("Login timed out");
        }
    }

    Connections {
        target: Greetd

        // An info or error line answers itself: Quickshell sends greetd the empty reply
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (!responseRequired) {
                if (message !== "")
                    root.info = root.info.concat([message]);
                root.message = message;
                root.error = error;
                return;
            }
            if (!echoResponse && root.password !== "") {
                Greetd.respond(root.password);
                root.password = "";
                return;
            }
            root.busy = false;
            root.prompt = message;
            root.echo = echoResponse;
        }

        function onAuthFailure(message) {
            Logger.warn("Greeter: login failed:", message);
            root.fail("Incorrect password");
        }

        function onError(error) {
            // After a failed login Quickshell cancels the session, and greetd answers that with an
            // error: its PAM worker has already gone (greetd context.rs cancel). Not this attempt's.
            if (settle.running) {
                Logger.info("Greeter: greetd error after a failed login:", error);
                return;
            }
            Logger.error("Greeter: greetd error:", error);
            root.fail("Login error");
        }

        function onReadyToLaunch() {
            // Not a real success: the reply to a cancel taken for one (quickshell #1266)
            if (!root.busy || Greetd.state !== GreetdState.ReadyToLaunch) {
                Logger.warn("Greeter: not ready to launch");
                root.fail("Login error");
                return;
            }
            root.launching();
            Greetd.launch(root.session.command, root.session.env, true);
        }
    }
}
