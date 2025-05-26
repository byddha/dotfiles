import asyncio
import math
import subprocess
import json
import threading
import time

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GLib, GtkLayerShell

import cairo

from hyprsnake.event_bus import EventBus  # Assuming hyprsnake.event_bus is available
from evdev import UInput, ecodes as e

# ----- Configuration -----
TARGET_FPS = 240.0
IDEAL_FRAME_DURATION = 1.0 / TARGET_FPS

ROT_SPEED_PER_SEC = 0.1 * 60.0
MAX_SPEED_PER_SEC = 10 * 60.0
STRAFE_SPEED_PER_SEC = 5.0 * 60.0

# ----- State -----
state = {
    "rotate_left": False,
    "rotate_right": False,
    "forward": False,
    "backward": False,
    "strafe_left": False,
    "strafe_right": False,
    "reverse": False,
    "boost": False,
    "angle": 0.0,
    "cursor_x": 0,
    "cursor_y": 0,
    "current_submap": "",  # Added to track the current submap
}

# ----- Key mapping -----
KEY_ACTIONS = {
    e.KEY_W: "forward",
    e.KEY_S: "backward",
    e.KEY_A: "rotate_left",
    e.KEY_D: "rotate_right",
    e.KEY_Q: "strafe_left",
    e.KEY_E: "strafe_right",
    e.KEY_R: "reverse",
    e.KEY_SPACE: "boost",
}


class OrbitalOverlay(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_decorated(False)
        self.set_app_paintable(True)
        self.set_can_focus(False)
        self.set_focus_on_map(False)

        try:
            self.set_pass_through(True)
        except AttributeError:
            self.connect("map-event", self.on_map_event_for_input_shape)

        display = Gdk.Display.get_default()
        primary_monitor = None
        if display:
            primary_monitor = display.get_primary_monitor()
            if not primary_monitor and display.get_n_monitors() > 0:
                primary_monitor = display.get_monitor(0)

        if primary_monitor:
            geom = primary_monitor.get_workarea()
            self.set_default_size(geom.width, geom.height)
        else:
            self.set_default_size(1920, 1080)

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        try:
            GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)
        except AttributeError:
            GtkLayerShell.set_keyboard_interactivity(self, False)

        for anchor_edge in (
            GtkLayerShell.Edge.TOP,
            GtkLayerShell.Edge.BOTTOM,
            GtkLayerShell.Edge.LEFT,
            GtkLayerShell.Edge.RIGHT,
        ):
            GtkLayerShell.set_anchor(self, anchor_edge, True)

        screen = self.get_screen()
        if screen:
            visual = screen.get_rgba_visual()
            if visual and screen.is_composited():
                self.set_visual(visual)
            elif visual:  # Fallback if not composited but RGBA is available
                self.set_visual(visual)

        self.connect("draw", self.on_draw)
        self.timer_id = GLib.timeout_add(
            int(IDEAL_FRAME_DURATION * 1000), self._periodic_redraw_trigger
        )
        # Initially hide the window until the correct submap is active
        self.hide()

    def on_map_event_for_input_shape(self, widget, event):
        gdk_window = widget.get_window()
        if gdk_window:
            empty_region = cairo.Region()
            gdk_window.input_shape_combine_region(empty_region, 0, 0)

    def _periodic_redraw_trigger(self):
        if state.get("current_submap") != "mouse":
            # If not in mouse submap, ensure it's hidden and stop continuous redraws for this state
            if self.is_visible():
                GLib.idle_add(self.hide)  # Schedule hide on main GTK thread
            return GLib.SOURCE_CONTINUE  # Keep timer active for when submap changes

        # Only show and queue draw if in "mouse" submap
        if not self.is_visible():
            GLib.idle_add(self.show_all)  # Schedule show on main GTK thread

        gdk_window = self.get_window()
        if gdk_window and gdk_window.is_visible():
            self.queue_draw()
            return GLib.SOURCE_CONTINUE
        return (
            GLib.SOURCE_REMOVE
        )  # Should ideally not be removed unless window is destroyed

    def on_draw(self, widget, cr):
        if state.get("current_submap") != "mouse":
            # Clear if visible but not in correct submap (e.g., during transition)
            cr.set_operator(cairo.OPERATOR_CLEAR)
            cr.paint()
            cr.set_operator(cairo.OPERATOR_OVER)
            return False

        cr.set_operator(cairo.OPERATOR_CLEAR)
        cr.paint()
        cr.set_operator(cairo.OPERATOR_OVER)

        # Use a copy of state to avoid issues if it's modified by another thread
        current_state = state.copy()
        mx = current_state.get("cursor_x", 0) - 482  # Offset, adjust as needed
        my = current_state.get("cursor_y", 0)
        current_angle = current_state.get("angle", 0.0)
        r = 15

        cr.arc(mx, my, r, 0, 2 * math.pi)
        cr.set_line_width(2)
        cr.set_source_rgba(1, 1, 1, 0.8)  # White, slightly transparent
        cr.stroke()

        # Line indicating direction
        x2 = mx + math.cos(current_angle) * r
        y2 = my + math.sin(current_angle) * r
        cr.move_to(mx, my)
        cr.line_to(x2, y2)
        cr.stroke()
        return False


async def movement_loop():
    capabilities = {
        e.EV_KEY: [e.BTN_LEFT],
        e.EV_REL: [e.REL_X, e.REL_Y],
    }
    ui = None
    try:
        ui = UInput(
            capabilities, name="orbital-virtual-mouse", version=0x1, bustype=e.BUS_USB
        )
    except Exception as err:
        print(
            f"[ERROR] Failed to create UInput device: {err}. Mouse movement will be disabled."
        )
        ui = None

    # Monitor dimensions (default, can be updated)
    # monitor_width, monitor_height = 3440, 1440
    # try:
    #     out = subprocess.check_output(["hyprctl", "monitors", "-j"])
    #     mons = json.loads(out)
    #     monitor_data = next((m for m in mons if m.get("primary")), None) or next(
    #         (m for m in mons if m.get("focused")), mons[0] if mons else None
    #     )
    #     if monitor_data:
    #         monitor_width, monitor_height = (
    #             monitor_data["width"],
    #             monitor_data["height"],
    #         )
    # except Exception:
    #     pass # Keep default if hyprctl fails

    last_frame_time = time.monotonic()
    MAX_DELTA_T = 0.1  # Max time step to prevent large jumps
    accumulated_mouse_dx, accumulated_mouse_dy = 0.0, 0.0
    # loop_count = 0 # For debugging prints

    try:
        while True:
            current_frame_time = time.monotonic()
            delta_t = current_frame_time - last_frame_time
            last_frame_time = current_frame_time
            delta_t = min(delta_t, MAX_DELTA_T)
            if delta_t <= 0:  # Ensure positive delta_t
                delta_t = IDEAL_FRAME_DURATION

            # --- SUBMAP CHECK ---
            if state.get("current_submap") != "mouse":
                # Reset accumulated movement if not in mouse mode to prevent sudden jumps
                accumulated_mouse_dx, accumulated_mouse_dy = 0.0, 0.0
                await asyncio.sleep(IDEAL_FRAME_DURATION)  # Sleep to reduce CPU usage
                continue  # Skip processing if not in "mouse" submap

            frame_dx, frame_dy = 0.0, 0.0
            local_state = state.copy()  # Work with a copy for this iteration

            if local_state["rotate_left"]:
                state["angle"] -= ROT_SPEED_PER_SEC * delta_t
            if local_state["rotate_right"]:
                state["angle"] += ROT_SPEED_PER_SEC * delta_t
            if local_state["reverse"]:  # 'reverse' is a momentary action
                state["angle"] += math.pi
                state["reverse"] = False  # Reset after applying

            current_fwd_bwd_dir = 0
            if local_state["forward"]:
                current_fwd_bwd_dir = 1
            elif local_state["backward"]:
                current_fwd_bwd_dir = -1
            boost_mul = 2.0 if local_state["boost"] else 1.0

            # fwd_bwd_calculated_dist = 0.0 # For debugging
            if current_fwd_bwd_dir != 0:
                dist = MAX_SPEED_PER_SEC * current_fwd_bwd_dir * boost_mul * delta_t
                # fwd_bwd_calculated_dist = dist
                frame_dx += math.cos(state["angle"]) * dist
                frame_dy += math.sin(state["angle"]) * dist

            # strafe_calculated_dist_mag = 0.0 # For debugging
            strafe_angle = (
                state["angle"] + math.pi / 2
            )  # Perpendicular to current angle
            dist_strafe_magnitude = STRAFE_SPEED_PER_SEC * boost_mul * delta_t
            rx_strafe = math.cos(strafe_angle)
            ry_strafe = math.sin(strafe_angle)

            if local_state["strafe_left"]:
                # strafe_calculated_dist_mag = -dist_strafe_magnitude
                frame_dx -= rx_strafe * dist_strafe_magnitude
                frame_dy -= ry_strafe * dist_strafe_magnitude
            if local_state["strafe_right"]:
                # strafe_calculated_dist_mag = dist_strafe_magnitude
                frame_dx += rx_strafe * dist_strafe_magnitude
                frame_dy += ry_strafe * dist_strafe_magnitude

            accumulated_mouse_dx += frame_dx
            accumulated_mouse_dy += frame_dy

            int_dx_to_send, int_dy_to_send = 0, 0
            if accumulated_mouse_dx >= 1.0:
                int_dx_to_send = math.floor(accumulated_mouse_dx)
                accumulated_mouse_dx -= int_dx_to_send
            elif accumulated_mouse_dx <= -1.0:
                int_dx_to_send = math.ceil(accumulated_mouse_dx)
                accumulated_mouse_dx -= int_dx_to_send

            if accumulated_mouse_dy >= 1.0:
                int_dy_to_send = math.floor(accumulated_mouse_dy)
                accumulated_mouse_dy -= int_dy_to_send
            elif accumulated_mouse_dy <= -1.0:
                int_dy_to_send = math.ceil(accumulated_mouse_dy)
                accumulated_mouse_dy -= int_dy_to_send

            if ui and (int_dx_to_send != 0 or int_dy_to_send != 0):
                if int_dx_to_send != 0:
                    ui.write(e.EV_REL, e.REL_X, int_dx_to_send)
                if int_dy_to_send != 0:
                    ui.write(e.EV_REL, e.REL_Y, int_dy_to_send)
                ui.syn()

            try:
                out_pos = subprocess.check_output(["hyprctl", "cursorpos", "-j"])
                pos = json.loads(out_pos)
                state["cursor_x"], state["cursor_y"] = pos["x"], pos["y"]
            except Exception:
                pass  # Ignore if hyprctl fails, keep last known cursor pos

            processing_duration = time.monotonic() - current_frame_time
            sleep_for = IDEAL_FRAME_DURATION - processing_duration
            await asyncio.sleep(max(0, sleep_for))
    finally:
        if ui:
            print("[INFO] Closing UInput device.")
            ui.close()


def run_async(overlay_instance):  # Pass overlay instance
    try:
        asyncio.run(main_async(overlay_instance))
    except Exception as err:
        print(f"[ERROR] run_async: {err}")


async def main_async(overlay_instance):  # Pass overlay instance
    em = EventBus()

    @em.on("keydown")
    def on_keydown(keyboard, mods, keycode):
        if state.get("current_submap") != "mouse":
            return  # Only process keydown if in "mouse" submap

        action = KEY_ACTIONS.get(keycode - 8)  # Hyprland keycodes might be +8
        if action:
            state[action] = True
            # print(f"[DEBUG] Keydown: {action} (keycode: {keycode}) -> True")

    @em.on("keyup")
    def on_keyup(keyboard, mods, keycode):
        if state.get("current_submap") != "mouse":
            return  # Only process keyup if in "mouse" submap

        action = KEY_ACTIONS.get(keycode - 8)  # Hyprland keycodes might be +8
        if action:
            state[action] = False
            # print(f"[DEBUG] Keyup: {action} (keycode: {keycode}) -> False")

    @em.on("submap")
    def on_submap_change(name):
        print(f"[INFO] Submap changed to: {name}")
        state["current_submap"] = name
        # Explicitly manage overlay visibility from the main GTK thread
        if name == "mouse":
            if not overlay_instance.is_visible():
                GLib.idle_add(overlay_instance.show_all)
        else:
            if overlay_instance.is_visible():
                GLib.idle_add(overlay_instance.hide)
                # Reset movement keys when leaving mouse submap
                for key_action in KEY_ACTIONS.values():
                    state[key_action] = False

    try:
        await asyncio.gather(em.serve(), movement_loop())
    except Exception as err:
        print(f"[ERROR] main_async: {err}")
    finally:
        print("[INFO] Async event loop finished.")


if __name__ == "__main__":
    print("[INFO] Orbital Overlay Script starting...")
    # Create overlay instance first, so it can be passed to the async thread
    overlay = OrbitalOverlay()

    # Pass the overlay instance to the async thread
    async_thread = threading.Thread(target=run_async, args=(overlay,), daemon=True)
    async_thread.start()

    # The overlay is shown/hidden by the submap change logic now
    # overlay.show_all() # No longer needed here, managed by submap logic

    try:
        Gtk.main()
    except KeyboardInterrupt:
        print("[INFO] Script interrupted by user (Ctrl+C).")
    except Exception as err:
        print(f"[ERROR] __main__ Gtk.main loop: {err}")
    finally:
        print("[INFO] Script shutting down...")
        # Potentially add cleanup for async_thread if needed, though daemon=True helps
        # e.g., set a flag for movement_loop to exit, then async_thread.join(timeout=1)
        # For now, daemon thread will exit when main thread exits.
        # Ensure Gtk.main_quit() is called if it wasn't by KeyboardInterrupt
        GLib.idle_add(Gtk.main_quit)
        print("[INFO] Script finished or exited.")
