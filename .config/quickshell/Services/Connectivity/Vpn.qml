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

    // State properties
    property bool mullvadConnected: false
    property bool fortiConnected: false
    property bool fortiConnectionFailed: false

    // Mullvad location info (from JSON)
    property string mullvadCity: ""
    property string mullvadCountry: ""

    // FortiVPN uptime tracking
    property int fortiUptimeSeconds: 0
    readonly property int _fortiHours: Math.floor(fortiUptimeSeconds / 3600)
    readonly property int _fortiMinutes: Math.floor((fortiUptimeSeconds % 3600) / 60)
    readonly property string fortiUptime: String(_fortiHours).padStart(2, '0') + ":" + String(_fortiMinutes).padStart(2, '0')

    readonly property bool anyConnected: mullvadConnected || fortiConnected

    // Poll status every 5 seconds
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.updateStatus()
    }

    // FortiVPN uptime timer (tick every minute for HH:MM display)
    Timer {
        id: fortiUptimeTimer
        interval: 60000
        repeat: true
        onTriggered: {
            root.fortiUptimeSeconds = root.fortiUptimeSeconds + 60;
        }
    }

    onFortiConnectedChanged: {
        if (fortiConnected) {
            fortiUptimeTimer.start();
        } else {
            fortiUptimeTimer.stop();
            fortiUptimeSeconds = 0;
        }
    }

    // ==================
    // Mullvad Processes
    // ==================

    Process {
        id: mullvadStatusProc
        command: ["mullvad", "status", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.mullvadConnected = data.state === "connected";
                    if (data.details?.location) {
                        root.mullvadCity = data.details.location.city || "";
                        root.mullvadCountry = data.details.location.country || "";
                    }
                } catch (e) {
                    root.mullvadConnected = false;
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                root.mullvadConnected = false;
            }
        }
    }

    Process {
        id: mullvadConnectProc
        onExited: (code, status) => {
            root.updateStatus();
        }
    }

    // ==================
    // FortiVPN Processes
    // ==================

    Process {
        id: fortiStatusProc
        command: ["pgrep", "openfortivpn"]
        onExited: (code, status) => {
            root.fortiConnected = (code === 0);
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
        mullvadStatusProc.running = true;
        fortiStatusProc.running = true;
    }

    // ==================
    // Control Functions
    // ==================

    function connectMullvad() {
        if (fortiConnected)
            disconnectForti();
        mullvadConnectProc.command = ["mullvad", "connect"];
        mullvadConnectProc.running = true;
        Logger.info("Connecting to Mullvad...");
    }

    function disconnectMullvad() {
        mullvadConnectProc.command = ["mullvad", "disconnect"];
        mullvadConnectProc.running = true;
        Logger.info("Disconnecting Mullvad...");
    }

    function connectFortiWithPassword(password: string) {
        if (mullvadConnected)
            disconnectMullvad();
        fortiConnectionFailed = false;  // Clear any previous error
        fortiUptimeSeconds = 0;  // Reset uptime counter
        // Use execDetached for long-running daemon process
        Quickshell.execDetached(["bash", "-c", `sudo openfortivpn --set-dns=1 -p '${password}'`]);
        Logger.info("FortiVPN launched");
        // Check status after a delay to allow connection
        fortiConnectDelay.start();
    }

    function disconnectForti() {
        fortiDisconnectProc.running = true;
        Logger.info("Disconnecting FortiVPN...");
    }

    function toggleMullvad() {
        if (mullvadConnected)
            disconnectMullvad();
        else
            connectMullvad();
    }

    Component.onCompleted: {
        Logger.info("VPN service initialized");
        updateStatus();
    }
}
