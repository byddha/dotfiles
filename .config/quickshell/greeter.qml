import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Modules/Lock"
import "Utils"

/**
 * The greeter: the lock's view on every monitor, logging in through greetd. greetd starts it inside
 * its own compositor (greeter/start), which quits with it once the session is launched.
 *
 * It remembers the last user and session; with none yet, the first real user of the system and
 * Hyprland.
 */
ShellRoot {
    id: root

    property var remembered: ({})

    // Called when the sessions or the memory arrive, in either order
    function pickSession() {
        const list = sessionList.list;
        greetd.session = list.find(s => s.id === remembered.session) ?? list.find(s => s.id === "hyprland") ?? list[0] ?? null;
    }

    // No reload while it runs: the files may change under it
    Binding {
        target: Quickshell
        property: "watchFiles"
        value: false
    }

    Sessions {
        id: sessionList

        onListChanged: root.pickSession()
    }

    LockInput {
        id: lockInput
    }

    GreetdAuth {
        id: greetd

        onLaunching: memory.setText(JSON.stringify({
            user: user,
            session: session?.id ?? ""
        }))
    }

    FileView {
        id: memory

        path: Quickshell.statePath("greeter.json")
        blockLoading: true
        // Written before the launch, after which the greeter quits at once
        blockWrites: true
        // Missing until the first login
        printErrors: false

        onSaveFailed: error => Logger.warn("Greeter: memory not written:", error)

        onLoaded: {
            try {
                root.remembered = JSON.parse(text());
            } catch (e) {
                Logger.warn("Greeter: memory not read:", e);
            }
            if (root.remembered.user)
                greetd.user = root.remembered.user;
            root.pickSession();
        }
    }

    // The first real user (UID 1000 up, with a login shell), when no user is remembered
    FileView {
        path: "/etc/passwd"
        blockLoading: true

        onLoaded: {
            const user = text().split("\n").map(line => line.split(":")).find(f => Number(f[2]) >= 1000 && Number(f[2]) < 60000 && !/(nologin|false)$/.test(f[6] ?? ""));
            if (!root.remembered.user && greetd.user === "")
                greetd.user = user?.[0] ?? "";
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData

            screen: modelData
            color: "black"
            WlrLayershell.namespace: "bidshell:greeter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: LockConfig.isPrimary(modelData) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            LockView {
                anchors.fill: parent
                screen: window.modelData
                auth: greetd
                input: lockInput
                context: "greeter"
                sessions: sessionList
            }
        }
    }
}
