pragma Singleton

import QtQuick
import Quickshell
import "../Services"

/**
 * Popouts - The open popouts and the bar windows, under one focus grab.
 *
 * Opening a popout closes the others, except the one it opened from (the tray menu over the tray
 * overflow); closing a popout closes the ones opened from it.
 * One grab for all: Hyprland has one per seat, so a second grab would end the first one. The bars are in
 * it, so a click on a bar reaches the bar instead of only ending the grab.
 */
Singleton {
    id: root

    property var bars: []
    property var open: []

    function registerBar(window) {
        bars = bars.concat([window]);
    }

    function unregisterBar(window) {
        bars = bars.filter(w => w !== window);
    }

    function opened(popout) {
        const others = open.filter(p => p !== popout.parentPopout);
        open = open.filter(p => p === popout.parentPopout).concat([popout]);
        others.forEach(p => p.dismiss());
    }

    function closed(popout) {
        open = open.filter(p => p !== popout);
        open.filter(p => p.parentPopout === popout).forEach(p => p.dismiss());
    }

    FocusGrab {
        id: grab
        // The bars join after the grab started: Hyprland gives the keyboard to an arbitrary surface of a new grab, which could be a bar
        windows: grab.active ? root.open.concat(root.bars) : root.open
        active: Compositor.hasFocusGrab && root.open.length > 0 && root.open.every(p => p.presented)
        onCleared: root.open.forEach(p => p.dismiss())
    }
}
