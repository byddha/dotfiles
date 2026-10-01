#!/usr/bin/env python3
"""Runs bidshell's KWin script and relays it for KWinBackend.qml.

The script sends KWin's state over D-Bus; each change goes out as one JSON line on stdout, with each
output's config key added. Actions come in as JSON lines on stdin and run as one-shot KWin scripts.
Exits when stdin closes or the parent dies, and unloads its scripts then.
"""
import ctypes
import glob
import json
import os
import signal
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

SERVICE = "org.bidshell.KWin"
SCRIPT = "bidshell"
ACTION = "bidshell-action"
HERE = os.path.dirname(os.path.abspath(__file__))
ACTION_FILE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "bidshell-kwin-action.js")
INTERFACE = Gio.DBusNodeInfo.new_for_xml(f"""
<node><interface name="{SERVICE}"><method name="State"><arg type="s" direction="in"/></method></interface></node>
""").interfaces[0]

bus = Gio.bus_get_sync(Gio.BusType.SESSION)
loop = GLib.MainLoop()
pending = None
keys = {}


def kwin(path, interface, method, args=None):
    return bus.call_sync("org.kde.KWin", path, interface, method, args, None, Gio.DBusCallFlags.NONE, -1, None)


def unload(plugin):
    kwin("/Scripting", "org.kde.kwin.Scripting", "unloadScript", GLib.Variant("(s)", (plugin,)))


def run_script(path, plugin):
    unload(plugin)
    script_id = kwin("/Scripting", "org.kde.kwin.Scripting", "loadScript", GLib.Variant("(ss)", (path, plugin))).unpack()[0]
    kwin(f"/Scripting/Script{script_id}", "org.kde.kwin.Script", "run")


def monitor_key(output):
    """The monitor's model as Hyprland reports it: the EDID monitor name, or the product code without one."""
    for path in glob.glob(f"/sys/class/drm/card*-{output}/edid"):
        edid = open(path, "rb").read()
        if len(edid) < 128:
            continue
        for start in range(54, 126, 18):
            block = edid[start:start + 18]
            if block[:3] == b"\0\0\0" and block[3] == 0xFC:
                name = block[5:].split(b"\n")[0].decode("ascii", "replace").strip(" \0")
                if name and name.isprintable():
                    return name
        return f"0x{int.from_bytes(edid[10:12], 'little'):04X}"
    return output


def flush():
    global pending
    state = json.loads(pending)
    pending = None
    for output in state["outputs"]:
        output["key"] = keys.setdefault(output["name"], monitor_key(output["name"]))
    print(json.dumps(state), flush=True)
    return False


def on_call(connection, sender, path, interface, method, params, invocation):
    global pending
    if pending is None:
        GLib.idle_add(flush)
    pending = params.unpack()[0]
    invocation.return_value(None)


def act(command):
    if command["action"] == "logout":
        bus.call_sync("org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown", "logout", None, None, Gio.DBusCallFlags.NONE, -1, None)
        return
    if command["action"] == "switch":
        body = f"""const desktop = workspace.desktops.find(d => d.x11DesktopNumber === {json.dumps(command["desktop"])});
const output = workspace.screens.find(s => s.name === {json.dumps(command["output"])});
if (desktop && output)
    workspace.setCurrentDesktopForScreen(desktop, output);
else if (desktop)
    workspace.currentDesktop = desktop;"""
    elif command["action"] == "focus":
        body = f"""const window = workspace.windowList().find(w => w.internalId.toString() === {json.dumps(command["id"])});
if (window)
    workspace.activeWindow = window;"""
    else:
        print(f"kwin_bridge: unknown action {command['action']}", file=sys.stderr)
        return
    with open(ACTION_FILE, "w") as f:
        f.write(body)
    run_script(ACTION_FILE, ACTION)


def on_stdin(channel, condition):
    line = sys.stdin.readline()
    if not line:
        loop.quit()
        return False
    try:
        act(json.loads(line))
    except (ValueError, KeyError, GLib.Error) as e:
        print(f"kwin_bridge: {line.strip()}: {e}", file=sys.stderr)
    return True


# Only now does the script's first state reach this bridge, not the one it replaces
def on_name_acquired(*_):
    run_script(os.path.join(HERE, "bidshell.js"), SCRIPT)


def on_name_lost(*_):
    loop.quit()


def owns_name():
    try:
        owner = bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "GetNameOwner",
                              GLib.Variant("(s)", (SERVICE,)), None, Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
    except GLib.Error:
        return False
    return owner == bus.get_unique_name()


def main():
    # PR_SET_PDEATHSIG: SIGTERM when quickshell dies, even without closing stdin
    ctypes.CDLL(None).prctl(1, signal.SIGTERM)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, loop.quit)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, loop.quit)

    bus.register_object("/bidshell", INTERFACE, on_call)
    # A new bridge (after a reload) takes the name over, and the old one exits
    Gio.bus_own_name_on_connection(bus, SERVICE, Gio.BusNameOwnerFlags.ALLOW_REPLACEMENT | Gio.BusNameOwnerFlags.REPLACE,
                                   on_name_acquired, on_name_lost)
    GLib.io_add_watch(GLib.IOChannel.unix_new(sys.stdin.fileno()), GLib.PRIORITY_DEFAULT,
                      GLib.IOCondition.IN | GLib.IOCondition.HUP, on_stdin)
    try:
        loop.run()
    finally:
        # A bridge that took the name over (a reload) runs the scripts now; only the last one unloads them
        if owns_name():
            unload(SCRIPT)
            unload(ACTION)


if __name__ == "__main__":
    main()
