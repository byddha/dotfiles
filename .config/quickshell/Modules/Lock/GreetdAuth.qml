import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import "../../Utils"

// The greeter's auth: logs `user` in through greetd, then starts `session`
Item {
    id: root

    property string user: ""
    // {command: [...], env: [...]}, from Sessions
    property var session: null
    property bool busy: false
    property string message: ""
    property bool error: false
    // A question greetd asks besides the password (e.g. a one-time code): the field answers it, shown
    // as typed when `echo`
    property string prompt: ""
    property bool echo: false
    property string password: ""

    signal failed
    // Before the session starts and the greeter quits: the time to remember the user and session
    signal launching

    function submit(text) {
        if (busy)
            return;
        error = false;
        message = "";
        busy = true;
        if (prompt !== "") {
            prompt = "";
            echo = false;
            Greetd.respond(text);
            return;
        }
        if (!Greetd.available) {
            fail("greetd is not running");
            return;
        }
        password = text;
        Greetd.createSession(user);
    }

    function cancel() {
        if (prompt === "")
            return;
        prompt = "";
        echo = false;
        Greetd.cancelSession();
    }

    function fail(text) {
        busy = false;
        password = "";
        prompt = "";
        echo = false;
        error = true;
        message = text;
        failed();
    }

    Connections {
        target: Greetd

        // An info or error line answers itself: Quickshell sends greetd the empty reply
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (!responseRequired) {
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
            Logger.error("Greeter: greetd error:", error);
            root.fail("Login error");
        }

        function onReadyToLaunch() {
            root.launching();
            launch.start();
        }
    }

    // A moment for `launching` to write what it remembers: the greeter quits on launch
    Timer {
        id: launch

        interval: 150
        onTriggered: Greetd.launch(root.session?.command ?? [], root.session?.env ?? [], true)
    }
}
