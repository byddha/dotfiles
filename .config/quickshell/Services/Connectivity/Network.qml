pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "."
import "../../Utils"
import ".."

Singleton {
    id: root

    // Connection state
    property bool ethernet: false
    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget: null

    // Network lists
    readonly property list<WifiAccessPoint> wifiNetworks: []
    readonly property WifiAccessPoint active: wifiNetworks.find(n => n.active) ?? null
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })

    // ==================
    // Control Functions
    // ==================

    function enableWifi(enabled: bool) {
        Logger.info("WiFi", enabled ? "enabling" : "disabling");
        const cmd = enabled ? "on" : "off";
        enableWifiProc.command = ["nmcli", "radio", "wifi", cmd];
        enableWifiProc.running = true;
    }

    function toggleWifi() {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi() {
        Logger.debug("WiFi scanning...");
        wifiScanning = true;
        rescanProcess.running = true;
    }

    function connectToWifiNetwork(accessPoint: WifiAccessPoint) {
        Logger.info("Connecting to:", accessPoint.ssid);
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        connectProc.command = ["nmcli", "dev", "wifi", "connect", accessPoint.ssid];
        connectProc.running = true;
    }

    function disconnectWifiNetwork() {
        if (active) {
            Logger.info("Disconnecting from:", active.ssid);
            disconnectProc.command = ["nmcli", "connection", "down", active.ssid];
            disconnectProc.running = true;
        }
    }

    function changePassword(network: WifiAccessPoint, password: string) {
        network.askingPassword = false;
        changePasswordProc.environment = {
            "PASSWORD": password
        };
        changePasswordProc.command = ["bash", "-c", `nmcli connection modify "${network.ssid}" wifi-sec.psk "$PASSWORD"`];
        changePasswordProc.running = true;
    }

    // ==================
    // Processes
    // ==================

    Process {
        id: enableWifiProc
        onExited: root.update()
    }

    Process {
        id: connectProc
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: SplitParser {
            onRead: line => {
                getNetworks.running = true;
            }
        }
        stderr: SplitParser {
            onRead: line => {
                if (line.includes("Secrets were required")) {
                    if (root.wifiConnectTarget) {
                        root.wifiConnectTarget.askingPassword = true;
                    }
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                Logger.info("Connected successfully");
            } else {
                Logger.warn("Connection failed, code:", exitCode);
            }
            if (root.wifiConnectTarget) {
                root.wifiConnectTarget.askingPassword = (exitCode !== 0);
            }
            root.wifiConnectTarget = null;
            root.update();
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
        onExited: root.update()
    }

    Process {
        id: changePasswordProc
        onExited: {
            // Re-attempt connection after changing password
            if (root.wifiConnectTarget) {
                connectProc.command = ["nmcli", "dev", "wifi", "connect", root.wifiConnectTarget.ssid];
                connectProc.running = true;
            }
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: {
                root.wifiScanning = false;
                getNetworks.running = true;
            }
        }
        onExited: root.wifiScanning = false
    }

    // ==================
    // Status Updates
    // ==================

    function update() {
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true;
    }

    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    Process {
        id: updateConnectionType
        property string buffer: ""
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE d status && nmcli -t -f CONNECTIVITY g"]
        running: true

        function startCheck() {
            buffer = "";
            running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }

        onExited: (exitCode, exitStatus) => {
            const lines = buffer.trim().split('\n');
            lines.pop(); // connectivity line
            root.ethernet = lines.some(line => line.includes("ethernet") && line.includes("connected"));
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        Component.onCompleted: running = true
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: getNetworks
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]) || 0,
                        frequency: parseInt(net[2]) || 0,
                        ssid: net[3] || "",
                        bssid: (net[4] || "").replace(rep2, ":"),
                        security: net[5] || ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                    }
                }

                const wifiNetworks = Array.from(networkMap.values());
                const rNetworks = root.wifiNetworks;

                // Remove destroyed networks
                const destroyed = rNetworks.filter(rn => !wifiNetworks.find(n => n.ssid === rn.ssid));
                for (const network of destroyed) {
                    const idx = rNetworks.indexOf(network);
                    if (idx >= 0) {
                        rNetworks.splice(idx, 1);
                        network.destroy();
                    }
                }

                // Update or create networks
                for (const network of wifiNetworks) {
                    const match = rNetworks.find(n => n.ssid === network.ssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    Component {
        id: apComp
        WifiAccessPoint {}
    }

    Component.onCompleted: {
        Logger.info("Service initialized");
        update();
    }
}
