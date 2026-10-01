// Loaded into KWin by kwin_bridge.py. Sends the whole state to the bridge on every change; the bridge coalesces.
const SERVICE = "org.bidshell.KWin";

// Layer-shell surfaces (bars, popups) show up as normal windows that skip the taskbar, pager and switcher
function isAppWindow(w) {
    return w.managed && (w.normalWindow || w.dialog) && !(w.skipTaskbar && w.skipPager && w.skipSwitcher);
}

function rect(g) {
    return [g.x, g.y, g.width, g.height];
}

function state() {
    return {
        windows: workspace.windowList().filter(isAppWindow).map(w => ({
            id: w.internalId.toString(),
            appId: w.resourceClass,
            title: w.caption,
            desktops: w.desktops.map(d => d.x11DesktopNumber),
            onAllDesktops: w.onAllDesktops,
            output: w.output.name,
            geometry: rect(w.frameGeometry),
            fullScreen: w.fullScreen,
            minimized: w.minimized,
            active: w.active
        })),
        outputs: workspace.screens.map(s => ({
            name: s.name,
            geometry: rect(s.geometry),
            area: rect(workspace.clientArea(KWin.MaximizeArea, s, workspace.currentDesktopForScreen(s))),
            scale: s.devicePixelRatio,
            desktop: workspace.currentDesktopForScreen(s).x11DesktopNumber
        })),
        desktopCount: workspace.desktops.length,
        activeOutput: workspace.activeScreen.name,
        perOutputDesktops: options.perOutputVirtualDesktops
    };
}

function send() {
    callDBus(SERVICE, "/bidshell", SERVICE, "State", JSON.stringify(state()));
}

function watch(w) {
    // A drag or resize sends its end only; the map and the region selector need no frame in between
    w.frameGeometryChanged.connect(() => {
        if (!w.move && !w.resize)
            send();
    });
    for (const changed of [w.interactiveMoveResizeFinished, w.captionChanged, w.desktopsChanged, w.outputChanged, w.fullScreenChanged, w.minimizedChanged])
        changed.connect(send);
}

let activeOutput = workspace.activeScreen.name;
// activeScreen has no change signal; it follows the pointer or the focused window
workspace.cursorPosChanged.connect(() => {
    if (workspace.activeScreen.name !== activeOutput) {
        activeOutput = workspace.activeScreen.name;
        send();
    }
});

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(w => {
    watch(w);
    send();
});
for (const changed of [workspace.windowRemoved, workspace.windowActivated, workspace.currentDesktopChanged, workspace.desktopsChanged, workspace.screensChanged, options.perOutputVirtualDesktopsChanged])
    changed.connect(send);
send();
