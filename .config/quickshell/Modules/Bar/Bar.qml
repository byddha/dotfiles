import QtQuick
import Quickshell

Scope {
    Variants {
        model: Quickshell.screens

        delegate: BarWindow {}
    }
}
