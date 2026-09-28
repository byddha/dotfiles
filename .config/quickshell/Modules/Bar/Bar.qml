import QtQuick
import Quickshell

Scope {
    Variants {
        model: Quickshell.screens

        delegate: Scope {
            id: perScreen

            required property ShellScreen modelData

            BarExclusion {
                modelData: perScreen.modelData
            }
            BarWindow {
                modelData: perScreen.modelData
            }
        }
    }
}
