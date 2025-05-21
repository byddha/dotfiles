import asyncio
import math
import subprocess
import json
import threading

import gi

# GTK3 and Layer Shell introspection
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GLib, GtkLayerShell

# Pycairo for operators
import cairo

from hyprsnake.event_bus import (
    EventBus,
)  # Assuming this is correctly installed and working
from evdev import ecodes

# ----- Configuration -----
TICK_RATE = 1 / 60  # ~60 FPS
ROT_SPEED = 0.12  # radians per tick
BASE_SPEED = 8.5  # px per tick
ACCEL_RATE = 0.52  # speed units per tick
STRAFE_SPEED = 5.0  # px per tick

# ----- State -----
# Ensure your state dictionary is defined before this class,
# especially if you use the hyprctl cursor position method.
# For example:
state = {
    "rotate_left": False,
    "rotate_right": False,
    "forward": False,
    "backward": False,
    "strafe_left": False,
    "strafe_right": False,
    "reverse": False,
    "boost": False,
    # internal trackers
    "angle": 0.0,
    "speed": 0.0,
    "last_dir": None,
    # For hyprctl cursor position method (if GDK fails)
    "cursor_x": 0,
    "cursor_y": 0,
}

# ----- Key mapping (example, ensure it's defined before use in main_async) -----
KEY_ACTIONS = {
    ecodes.KEY_W: "forward",
    ecodes.KEY_S: "backward",
    ecodes.KEY_A: "rotate_left",
    ecodes.KEY_D: "rotate_right",
    ecodes.KEY_Q: "strafe_left",
    ecodes.KEY_E: "strafe_right",
    ecodes.KEY_R: "reverse",
    ecodes.KEY_SPACE: "boost",
}


# ----- Overlay window -----
class OrbitalOverlay(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.POPUP)
        self.set_decorated(False)
        self.set_app_paintable(True)

        # Fullscreen geometry
        display = Gdk.Display.get_default()
        primary_monitor = None
        if display:
            primary_monitor = display.get_primary_monitor()
            if not primary_monitor:  # Fallback if no primary is explicitly set
                if display.get_n_monitors() > 0:
                    primary_monitor = display.get_monitor(0)

        if primary_monitor:
            geom = primary_monitor.get_workarea()
            self.set_default_size(geom.width, geom.height)
        else:
            print(
                "[WARNING] __init__: Could not determine primary monitor geometry. Using fallback size 1920x1080."
            )
            self.set_default_size(1920, 1080)

        # Layer Shell setup
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        # Ensure the overlay does not try to grab keyboard focus
        GtkLayerShell.set_keyboard_interactivity(self, False)
        for edge in (
            GtkLayerShell.Edge.TOP,
            GtkLayerShell.Edge.BOTTOM,
            GtkLayerShell.Edge.LEFT,
            GtkLayerShell.Edge.RIGHT,
        ):
            GtkLayerShell.set_anchor(self, edge, True)

        # Enable transparency
        screen = self.get_screen()
        if screen:
            visual = screen.get_rgba_visual()
            if visual:
                self.set_visual(visual)
            else:
                print("[WARNING] __init__: RGBA visual not available for transparency.")
        else:
            print("[WARNING] __init__: Could not get screen for RGBA visual.")

        # Redraw at ~60Hz
        self.connect("draw", self.on_draw)
        # Store the timer ID so it could be removed if needed
        self.timer_id = GLib.timeout_add(
            int(TICK_RATE * 1000), self._periodic_redraw_trigger
        )
        print(
            f"[DEBUG] __init__: GLib.timeout_add scheduled with ID: {self.timer_id}, interval: {int(TICK_RATE * 1000)}ms"
        )

    def _periodic_redraw_trigger(self):
        # This function is called by GLib.timeout_add
        print("[DEBUG] _periodic_redraw_trigger: Timeout called.")
        # Check if the window is still valid and visible before queueing a draw
        # self.get_window() returns the Gdk.Window associated with the Gtk.Widget
        gdk_window = self.get_window()
        if gdk_window and gdk_window.is_visible():
            # print("[DEBUG] _periodic_redraw_trigger: Window is visible, queueing draw.")
            self.queue_draw()
            return GLib.SOURCE_CONTINUE  # IMPORTANT: Ensures the timeout is rescheduled
        else:
            if not gdk_window:
                print(
                    "[DEBUG] _periodic_redraw_trigger: GDK window no longer exists. Stopping timer."
                )
            elif not gdk_window.is_visible():
                print(
                    "[DEBUG] _periodic_redraw_trigger: Window not visible. Stopping timer."
                )
            return GLib.SOURCE_REMOVE  # Stops the timeout

    def on_draw(self, widget, cr):
        # This is called when GTK decides to redraw the window
        print("[DEBUG] on_draw: Execution started.")

        # Clear to transparent
        cr.set_operator(cairo.OPERATOR_CLEAR)
        cr.paint()
        cr.set_operator(cairo.OPERATOR_OVER)

        mx, my = 0, 0  # Default position

        mx = state.get("cursor_x", 0) - 482  # Use .get for safety
        my = state.get("cursor_y", 0)
        print(f"[DEBUG] on_draw: Using state-derived position: ({mx}, {my})")
        # print(f"[DEBUG] on_draw: Using state-derived position: ({mx}, {my})")

        current_angle = state.get("angle", 0.0)  # Use .get for safety
        # print(f"[DEBUG] on_draw: Drawing with angle: {current_angle}")

        # Draw circle indicator
        r = 15  # Radius of the circle
        cr.arc(mx, my, r, 0, 2 * math.pi)
        cr.set_line_width(2)
        cr.set_source_rgba(1, 1, 1, 0.8)  # White, slightly transparent
        cr.stroke()

        # Draw directional line
        x2 = mx + math.cos(current_angle) * r
        y2 = my + math.sin(current_angle) * r
        cr.move_to(mx, my)
        cr.line_to(x2, y2)
        cr.stroke()

        print("[DEBUG] on_draw: Execution finished.")
        return False  # Standard for "draw" signal handler, indicating event not fully handled here


# ----- Movement loop (ensure your movement_loop updates state["cursor_x"], state["cursor_y"] if use_hyprctl_pos_from_state is True) -----
async def movement_loop():
    # Get monitor resolution (Corrected parsing, though not directly used for ydotool issue)
    monitor_width, monitor_height = 3440, 1440
    try:
        out = subprocess.check_output(["hyprctl", "monitors", "-j"])
        mons = json.loads(out)
        monitor_data = next((m for m in mons if m.get("primary")), None)
        if not monitor_data:
            monitor_data = next(
                (m for m in mons if m.get("focused")), mons[0] if mons else None
            )

        if monitor_data:
            monitor_width, monitor_height = (
                monitor_data["width"],
                monitor_data["height"],
            )
            # print(f"[DEBUG] movement_loop: Monitor {monitor_width}x{monitor_height}")
    except Exception as e:
        print(
            f"[WARNING] movement_loop: Failed to get monitor info via hyprctl: {e}. Using default {monitor_width}x{monitor_height}."
        )

    while True:
        dx = dy = 0.0  # Initialize deltas for this tick

        # Rotation
        if state["rotate_left"]:
            state["angle"] -= ROT_SPEED
        if state["rotate_right"]:
            state["angle"] += ROT_SPEED
        if state["reverse"]:
            state["angle"] += math.pi
            state["reverse"] = False  # Consume reverse action

        # Forward/backward movement
        moving = state["forward"] or state["backward"]
        dir_val = 1 if state["forward"] else -1
        boost_mul = 2.0 if state["boost"] else 1.0

        if moving:
            if dir_val == state["last_dir"]:
                state["speed"] = min(state["speed"] + ACCEL_RATE, BASE_SPEED)
            else:
                state["speed"] = ACCEL_RATE  # Reset speed if direction changes
            dx_fwd_bwd = math.cos(state["angle"]) * state["speed"] * dir_val * boost_mul
            dy_fwd_bwd = math.sin(state["angle"]) * state["speed"] * dir_val * boost_mul
            dx += dx_fwd_bwd
            dy += dy_fwd_bwd
            state["last_dir"] = dir_val
        else:
            state["speed"] = 0.0
            state["last_dir"] = None

        # Strafing
        # Strafe angle is 90 degrees (pi/2 radians) to the current direction
        strafe_angle = state["angle"] + math.pi / 2
        rx_strafe = math.cos(strafe_angle)
        ry_strafe = math.sin(strafe_angle)

        if state["strafe_left"]:
            dx -= (
                rx_strafe * STRAFE_SPEED * boost_mul
            )  # Subtract for left relative to forward
            dy -= ry_strafe * STRAFE_SPEED * boost_mul
        if state["strafe_right"]:
            dx += (
                rx_strafe * STRAFE_SPEED * boost_mul
            )  # Add for right relative to forward
            dy += ry_strafe * STRAFE_SPEED * boost_mul

        # Send relative movement only if there's a calculated delta
        if int(dx) != 0 or int(dy) != 0:
            try:
                subprocess.run(
                    ["ydotool", "mousemove", "--", str(int(dx)), str(int(dy))],
                    check=False,
                )  # check=False to not raise on error
            except FileNotFoundError:
                print(
                    "[ERROR] movement_loop: ydotool not found. Mouse movement will not work."
                )
            except Exception as e:
                print(f"[ERROR] movement_loop: ydotool command failed: {e}")

        # --- IMPORTANT ---
        # If use_hyprctl_pos_from_state is True in on_draw, update cursor_x/y here
        # This call is expensive, do it 60 times a second only if necessary.
        # Ensure this logic matches the `use_hyprctl_pos_from_state` in on_draw
        # For now, I'll assume it's enabled for the "GDK fails" scenario.
        try:
            out_pos = subprocess.check_output(["hyprctl", "cursorpos", "-j"])
            pos = json.loads(out_pos)
            state["cursor_x"] = pos["x"]
            state["cursor_y"] = pos["y"]
        except FileNotFoundError:
            print(
                "[ERROR] movement_loop: hyprctl not found. Cannot get cursor position for overlay."
            )
            # Potentially set state["cursor_x"], state["cursor_y"] to a fallback if needed
        except Exception as e:
            # print(f"[WARNING] movement_loop: Could not get hyprctl cursorpos: {e}")
            pass  # Keep last known position or let it default if first time

        await asyncio.sleep(TICK_RATE)


# ----- Entrypoint -----
def run_async():
    # This function will run in a separate thread
    print("[DEBUG] run_async: Starting asyncio event loop.")
    try:
        asyncio.run(main_async())
    except Exception as e:
        print(f"[ERROR] run_async: Exception in asyncio tasks: {e}")
    print("[DEBUG] run_async: Asyncio event loop finished.")


async def main_async():
    print("[DEBUG] main_async: Initializing EventBus.")
    em = EventBus()  # Make sure hyprsnake.event_bus.EventBus is correct

    @em.on("keydown")
    def on_keydown(keyboard, mods, keycode):
        # print(f"[DEBUG] on_keydown: keycode={keycode}, mods={mods}")
        kc = (
            keycode - 8
        )  # Assuming keycode from hyprsnake needs this adjustment for evdev codes
        action = KEY_ACTIONS.get(kc)
        if action:
            # print(f"[DEBUG] on_keydown: Action '{action}' set to True.")
            state[action] = True

    @em.on("keyup")
    def on_keyup(keyboard, mods, keycode):
        # print(f"[DEBUG] on_keyup: keycode={keycode}, mods={mods}")
        kc = keycode - 8  # Assuming keycode from hyprsnake needs this adjustment
        action = KEY_ACTIONS.get(kc)
        if action:
            # print(f"[DEBUG] on_keyup: Action '{action}' set to False.")
            state[action] = False

    print("[DEBUG] main_async: Starting EventBus serve and movement_loop.")
    # Run event bus listening and movement loop concurrently
    try:
        await asyncio.gather(em.serve(), movement_loop())
    except Exception as e:
        print(f"[ERROR] main_async: Exception during asyncio.gather: {e}")
    print("[DEBUG] main_async: asyncio.gather finished.")


if __name__ == "__main__":
    print("[DEBUG] __main__: Script started.")
    # Start the asyncio tasks in a daemon thread
    # Daemon means this thread will exit when the main program (GTK loop) exits
    async_thread = threading.Thread(target=run_async, daemon=True)
    print("[DEBUG] __main__: Starting asyncio thread.")
    async_thread.start()

    print("[DEBUG] __main__: Creating OrbitalOverlay.")
    overlay = OrbitalOverlay()
    print("[DEBUG] __main__: Showing overlay.")
    overlay.show_all()

    print("[DEBUG] __main__: Starting Gtk.main().")
    try:
        Gtk.main()
    except KeyboardInterrupt:
        print("[DEBUG] __main__: Gtk.main() interrupted by user (KeyboardInterrupt).")
    except Exception as e:
        print(f"[ERROR] __main__: Exception in Gtk.main(): {e}")
    finally:
        print("[DEBUG] __main__: Gtk.main() finished or exited.")
        # If you need to explicitly stop the async thread on GTK exit,
        # you might need a more complex shutdown mechanism (e.g., asyncio.Event)
        # For a daemon thread, it will be terminated when the main thread ends.
