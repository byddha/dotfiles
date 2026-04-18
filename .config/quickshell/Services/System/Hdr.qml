pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../../Config"
import "../../Utils"

Singleton {
    id: root

    property bool enabled: false
    property var hdrMonitors: []
    property bool pendingToggle: false

    function refresh() {
        checkState();
    }

    function toggle() {
        if (hdrMonitors.length === 0)
            return;
        pendingToggle = true;
        checkState();
    }

    function checkState() {
        const monitors = Compositor.monitors;
        const configMonitors = Config.options?.monitors || {};

        root.hdrMonitors = [];
        for (const mon of monitors) {
            if (configMonitors[mon.model]?.hdrCapable) {
                root.hdrMonitors.push(mon.name);
            }
        }

        for (const mon of monitors) {
            if (root.hdrMonitors.includes(mon.name)) {
                if (mon.colorManagementPreset === "hdr") {
                    root.enabled = true;
                    Logger.info("HDR state: enabled");
                    if (root.pendingToggle) {
                        root.pendingToggle = false;
                        root.doToggle();
                    }
                    return;
                }
            }
        }
        root.enabled = false;
        Logger.info("HDR state: disabled");

        if (root.pendingToggle) {
            root.pendingToggle = false;
            root.doToggle();
        }
    }

    function doToggle() {
        const newState = enabled ? "srgb" : "hdr";
        for (const mon of hdrMonitors) {
            Compositor.setMonitorColorManagement(mon, newState);
        }
    }

    Connections {
        target: Compositor
        function onMonitorDataUpdated() {
            checkState();
        }
    }

    Component.onCompleted: checkState()
}
