pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../../Config"

Singleton {
    id: root

    property bool enabled: false
    property var hdrMonitors: []

    function refresh() {
        checkState();
    }

    function toggle() {
        if (hdrMonitors.length === 0)
            return;
        checkState();
        doToggle();
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
                    return;
                }
            }
        }
        root.enabled = false;
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
