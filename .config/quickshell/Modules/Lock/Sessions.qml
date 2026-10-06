import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

// The Wayland sessions the greeter can start: wayland-sessions/ of the XDG data dirs (an earlier dir
// wins for the same file name), without the hidden ones and those whose TryExec is not installed
Item {
    id: root

    // [{id, name, command, env}], sorted by name
    property var list: []

    function parse(text) {
        const sessions = [];
        for (const file of text.split("\u0001").slice(1)) {
            const [path, ...lines] = file.split("\n");
            const fields = {};
            let inEntry = false;
            for (const line of lines) {
                if (line.startsWith("["))
                    inEntry = line.trim() === "[Desktop Entry]";
                else if (inEntry && line.includes("=")) {
                    const key = line.slice(0, line.indexOf("=")).trim();
                    if (!(key in fields))
                        fields[key] = line.slice(line.indexOf("=") + 1).trim();
                }
            }
            if (!fields.Exec || fields.NoDisplay === "true" || fields.Hidden === "true")
                continue;
            const id = path.split("/").pop().replace(/\.desktop$/, "");
            if (sessions.some(s => s.id === id))
                continue;
            const desktop = fields.DesktopNames?.split(";").filter(name => name !== "").join(":") ?? "";
            sessions.push({
                id: id,
                name: fields.Name || id,
                // Field codes (%f and the like) have no meaning for a session. Its output goes to the
                // journal: greetd leaves it on the console, where it would flash between the greeter
                // and the session.
                command: ["systemd-cat", "-t", id].concat(fields.Exec.split(/\s+/).filter(arg => arg !== "" && !/^%[a-zA-Z]$/.test(arg))),
                env: ["XDG_SESSION_TYPE=wayland", `XDG_SESSION_DESKTOP=${id}`, `DESKTOP_SESSION=${id}`].concat(desktop !== "" ? [`XDG_CURRENT_DESKTOP=${desktop}`] : [])
            });
        }
        return sessions.sort((a, b) => a.name.localeCompare(b.name));
    }

    Process {
        running: true
        command: ["sh", "-c", `IFS=:
            for dir in \${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do
                for f in "$dir"/wayland-sessions/*.desktop; do
                    [ -f "$f" ] || continue
                    try=$(sed -n 's/^TryExec=//p' "$f" | head -n 1)
                    [ -z "$try" ] || command -v "$try" >/dev/null 2>&1 || continue
                    printf '\\001%s\\n' "$f"
                    cat "$f"
                done
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.list = root.parse(text);
                if (root.list.length === 0)
                    Logger.error("Greeter: no Wayland sessions found");
            }
        }
    }
}
