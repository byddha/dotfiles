pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // External debug toggle - set from Config after init
    property bool debugEnabled: false

    // ANSI color codes
    readonly property string _reset: "\x1b[0m"
    readonly property string _dim: "\x1b[2m"
    readonly property string _red: "\x1b[31m"
    readonly property string _yellow: "\x1b[33m"
    readonly property string _cyan: "\x1b[36m"
    readonly property string _magenta: "\x1b[35m"
    readonly property string _gray: "\x1b[90m"

    readonly property int _padWidth: 25

    function _timestamp() {
        const d = new Date();
        const h = String(d.getHours()).padStart(2, '0');
        const m = String(d.getMinutes()).padStart(2, '0');
        const s = String(d.getSeconds()).padStart(2, '0');
        return `${h}:${m}:${s}`;
    }

    function _getCallerComponent() {
        try {
            throw new Error("");
        } catch (e) {
            const lines = e.stack.split('\n');
            // Skip Error line and Logger internal calls (usually first 3-4 lines)
            for (let i = 1; i < lines.length; i++) {
                const line = lines[i];
                // Skip Logger internal functions
                if (line.includes('Logger.qml'))
                    continue;

                // Try to extract QML filename from stack trace
                // Format varies: "at functionName (file:line:col)" or "file:line:col"
                const match = line.match(/([^\/\s]+\.qml):\d+/);
                if (match) {
                    return match[1].replace('.qml', '');
                }
            }
            return "Unknown";
        }
    }

    function _format(color, ...args) {
        const ts = _timestamp();
        const comp = _getCallerComponent().padStart(_padWidth, ' ');
        const msg = args.map(arg => {
            if (typeof arg === 'object') {
                try {
                    return JSON.stringify(arg);
                } catch (e) {
                    return String(arg);
                }
            }
            return String(arg);
        }).join(' ');
        return `${_dim}[${ts}]${_reset} ${_magenta}[${comp}]${_reset} ${color}${msg}${_reset}`;
    }

    function debug(...args) {
        if (root.debugEnabled) {
            console.debug(_format(_gray, ...args));
        }
    }

    function info(...args) {
        console.info(_format(_cyan, ...args));
    }

    function warn(...args) {
        console.warn(_format(_yellow, ...args));
    }

    function error(...args) {
        console.error(_format(_red, ...args));
    }
}
