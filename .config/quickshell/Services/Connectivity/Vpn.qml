pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

/**
 * Vpn - VPN management service
 *
 * Manages Mullvad (personal) and OpenFortiVPN (work) connections.
 * VPNs are mutually exclusive - connecting one disconnects the other.
 */
Singleton {
    id: root

    // State properties. mullvadState comes from `mullvad status listen`: connecting, connected,
    // disconnecting, disconnected or error.
    property string mullvadState: "disconnected"
    readonly property bool mullvadConnected: mullvadState === "connected"
    property bool fortiConnected: false
    property bool fortiConnectionFailed: false

    // Busy = a connect / disconnect was requested and has not finished yet. Pending covers the
    // gap between the command and the first state change it causes.
    property bool mullvadPending: false
    readonly property bool mullvadBusy: mullvadPending || mullvadState === "connecting" || mullvadState === "disconnecting"
    property bool fortiDisconnecting: false
    readonly property bool fortiConnecting: fortiConnectDelay.running
    readonly property bool fortiBusy: fortiConnecting || fortiDisconnecting
    readonly property bool busy: mullvadBusy || fortiBusy
    readonly property bool disconnecting: fortiDisconnecting || mullvadState === "disconnecting" || (mullvadPending && mullvadConnected)

    // Mullvad location info (from JSON)
    property string mullvadCity: ""
    property string mullvadCountry: ""

    // How long openfortivpn has been running, read with its status, so it survives shell restarts
    property int fortiUptimeSeconds: 0
    readonly property int _fortiHours: Math.floor(fortiUptimeSeconds / 3600)
    readonly property int _fortiMinutes: Math.floor((fortiUptimeSeconds % 3600) / 60)
    readonly property string fortiUptime: String(_fortiHours).padStart(2, '0') + ":" + String(_fortiMinutes).padStart(2, '0')

    readonly property bool anyConnected: mullvadConnected || fortiConnected

    // Forti has no event stream: poll, fast while a disconnect is pending
    Timer {
        interval: root.fortiDisconnecting ? 300 : 5000
        running: true
        repeat: true
        onTriggered: root.updateStatus()
    }

    // ==================
    // Mullvad Processes
    // ==================

    // Prints the current state at start, then one JSON line per change
    Process {
        id: mullvadListenProc
        // setpriv: the kernel ends it with qs, also when qs dies without cleaning up (SIGTERM, crash)
        command: ["setpriv", "--pdeathsig", "TERM", "--", "mullvad", "status", "-j", "listen"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    root.mullvadState = data.state ?? "disconnected";
                    root.mullvadPending = false;
                    if (data.details?.location) {
                        root.mullvadCity = data.details.location.city || "";
                        root.mullvadCountry = data.details.location.country || "";
                    }
                } catch (e) {
                    Logger.warn("Unreadable mullvad status line");
                }
            }
        }

        // Daemon restarted or mullvad missing: retry later
        onExited: mullvadListenRestart.start()
    }

    Timer {
        id: mullvadListenRestart
        interval: 10000
        onTriggered: mullvadListenProc.running = true
    }

    Timer {
        id: mullvadPendingTimeout
        interval: 15000
        onTriggered: root.mullvadPending = false
    }

    Process {
        id: mullvadConnectProc
        // A failed command causes no state change to clear the pending state
        onExited: code => {
            if (code !== 0)
                root.mullvadPending = false;
        }
    }

    // ==================
    // FortiVPN Processes
    // ==================

    // Prints the process's elapsed seconds, nothing when it is not running
    Process {
        id: fortiStatusProc
        command: ["ps", "-o", "etimes=", "-C", "openfortivpn"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seconds = parseInt(text.trim());
                root.fortiConnected = !isNaN(seconds);
                root.fortiUptimeSeconds = root.fortiConnected ? seconds : 0;
                if (!root.fortiConnected)
                    root.fortiDisconnecting = false;
            }
        }
    }

    // FortiVPN uses detached execution since it's a long-running daemon
    Timer {
        id: fortiConnectDelay
        interval: 3000
        onTriggered: {
            // Check if connection succeeded
            fortiCheckProc.running = true;
        }
    }

    Process {
        id: fortiCheckProc
        command: ["pgrep", "openfortivpn"]
        onExited: (code, status) => {
            if (code !== 0) {
                // Process not running = connection failed
                root.fortiConnectionFailed = true;
                Logger.warn("FortiVPN connection failed");
                // Clear error after 3 seconds
                fortiErrorClearTimer.start();
            }
            root.updateStatus();
        }
    }

    Timer {
        id: fortiDisconnectTimeout
        interval: 10000
        onTriggered: {
            if (root.fortiDisconnecting)
                Logger.warn("FortiVPN did not stop");
            root.fortiDisconnecting = false;
        }
    }

    Timer {
        id: fortiErrorClearTimer
        interval: 3000
        onTriggered: root.fortiConnectionFailed = false
    }

    Process {
        id: fortiDisconnectProc
        command: ["sudo", "killall", "openfortivpn"]
        onExited: (code, status) => {
            root.updateStatus();
        }
    }

    // ==================
    // Status Functions
    // ==================

    function updateStatus() {
        fortiStatusProc.running = true;
    }

    // ==================
    // Control Functions
    // ==================

    function connectMullvad() {
        if (fortiConnected)
            disconnectForti();
        mullvadPending = true;
        mullvadPendingTimeout.restart();
        mullvadConnectProc.command = ["mullvad", "connect"];
        mullvadConnectProc.running = true;
    }

    function disconnectMullvad() {
        mullvadPending = true;
        mullvadPendingTimeout.restart();
        mullvadConnectProc.command = ["mullvad", "disconnect"];
        mullvadConnectProc.running = true;
    }

    function connectFortiWithPassword(password: string) {
        if (mullvadConnected)
            disconnectMullvad();
        fortiConnectionFailed = false;  // Clear any previous error
        fortiUptimeSeconds = 0;  // Reset uptime counter
        // Detached so the tunnel survives shell reloads. The password goes in through stdin
        // (openfortivpn prompts on it), never through argv or the script text.
        Quickshell.execDetached({
            command: ["bash", "-c", 'exec sudo /usr/lib/bida/forti-up <<< "$FORTI_PASS"'],
            environment: {
                FORTI_PASS: password
            }
        });
        // Check status after a delay to allow connection
        fortiConnectDelay.start();
    }

    function disconnectForti() {
        fortiDisconnecting = true;
        fortiDisconnectTimeout.restart();
        fortiDisconnectProc.running = true;
    }

    function toggleMullvad() {
        if (mullvadBusy)
            return;
        if (mullvadConnected)
            disconnectMullvad();
        else
            connectMullvad();
    }

    Component.onCompleted: {
        updateStatus();
    }
}
