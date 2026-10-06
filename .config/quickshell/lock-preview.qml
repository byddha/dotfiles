import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Modules/Lock"

/**
 * The lock's design without locking: the same view on every monitor, over everything, with an auth
 * that never reaches PAM ("test" unlocks). For screenshots and tests:
 *
 *   qs -n -d -p ~/.config/quickshell/lock-preview.qml
 *   qs -p ~/.config/quickshell/lock-preview.qml ipc call preview state error   (idle, busy, error)
 *   qs -p ~/.config/quickshell/lock-preview.qml ipc call preview quit
 */
ShellRoot {
    FakeAuth {
        id: fakeAuth
    }

    LockInput {
        id: lockInput
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData

            screen: modelData
            color: "black"
            WlrLayershell.namespace: "bidshell:lock-preview"
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
                auth: fakeAuth
                input: lockInput
            }
        }
    }

    IpcHandler {
        target: "preview"

        function state(state: string): void {
            fakeAuth.setState(state);
        }

        function quit(): void {
            Qt.quit();
        }
    }
}
