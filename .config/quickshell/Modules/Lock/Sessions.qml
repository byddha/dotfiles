import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

// The Wayland sessions the greeter can start: /usr/share/wayland-sessions, without the hidden ones
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
            const desktop = fields.DesktopNames?.split(";").filter(name => name !== "").join(":") || id;
            sessions.push({
                id: id,
                name: fields.Name || id,
                // Field codes (%f and the like) have no meaning for a session
                command: fields.Exec.split(/\s+/).filter(arg => arg !== "" && !/^%[a-zA-Z]$/.test(arg)),
                env: ["XDG_SESSION_TYPE=wayland", `XDG_SESSION_DESKTOP=${id}`, `DESKTOP_SESSION=${id}`, `XDG_CURRENT_DESKTOP=${desktop}`]
            });
        }
        return sessions.sort((a, b) => a.name.localeCompare(b.name));
    }

    Process {
        running: true
        command: ["sh", "-c", "for f in /usr/share/wayland-sessions/*.desktop; do printf '\\001%s\\n' \"$f\"; cat \"$f\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.list = root.parse(text);
                if (root.list.length === 0)
                    Logger.error("Greeter: no sessions in /usr/share/wayland-sessions");
            }
        }
    }
}
