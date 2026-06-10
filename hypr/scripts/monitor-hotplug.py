#!/usr/bin/env python3
"""
Hyprland monitor hotplug handler.

Listens to Hyprland's IPC event socket and automatically switches between
dock mode (external monitors only) and laptop mode (built-in display) based
on monitor connect/disconnect events.

Uses a debounced timer so that rapid events during Thunderbolt link
negotiation (4–6 events in the first 2 seconds) are collapsed into a single
action that fires only after the topology has stabilised.
"""

import argparse
import json
import logging
import os
import socket
import subprocess
import threading
import time
from typing import Final

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger(__name__)

BUILTIN_MONITOR = "eDP-1"
BUILTIN_MONITOR_CONFIG = f"{BUILTIN_MONITOR},preferred,auto,1.3333334"
# Settle time after a topology event — long enough to outlast Thunderbolt
# link negotiation flapping (typically 4–6 events over ~2 seconds).
SETTLE_DELAY = 3.0
WAYBAR_RESTART_DELAY: Final[float] = 0.5

_timer: threading.Timer | None = None
_timer_lock = threading.Lock()


def get_socket_path() -> str:
    """Return the path to Hyprland's event socket (.socket2.sock)."""
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        raise RuntimeError("HYPRLAND_INSTANCE_SIGNATURE is not set")
    return os.path.join(runtime_dir, "hypr", sig, ".socket2.sock")


def get_monitors() -> list[dict]:
    """Return Hyprland's current monitor objects from ``hyprctl monitors -j``."""
    result = subprocess.run(
        ["hyprctl", "monitors", "-j"],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def get_monitor_state() -> tuple[bool, list[str]]:
    """Return (builtin_active, external_names) from the current monitor topology.

    Parses ``hyprctl monitors -j`` JSON output. Each monitor object has
    ``name``, ``disabled``, and ``dpmsStatus`` fields.

    Returns
    -------
    builtin_active:
        True when eDP-1 is present, not disabled, and DPMS-on.
    external_names:
        Names of all non-eDP-1 monitors that are not disabled.
    """
    monitors = get_monitors()
    builtin_active = False
    external_names: list[str] = []
    for mon in monitors:
        name = mon.get("name", "")
        disabled = mon.get("disabled", False)
        dpms_on = mon.get("dpmsStatus", True)
        if name == BUILTIN_MONITOR:
            builtin_active = (not disabled) and dpms_on
        elif not disabled:
            external_names.append(name)
    return builtin_active, external_names


def get_preferred_external_monitor() -> str | None:
    """Return the best external monitor to receive evacuated workspaces."""
    monitors = get_monitors()
    externals = [
        mon
        for mon in monitors
        if mon.get("name") != BUILTIN_MONITOR and not mon.get("disabled", False)
    ]
    if not externals:
        return None

    focused_external = next((mon for mon in externals if mon.get("focused")), None)
    if focused_external is not None:
        return focused_external["name"]

    return externals[0]["name"]


def evacuate_builtin_workspaces() -> None:
    """Move workspaces off the built-in display before dock mode hides it."""
    target_monitor = get_preferred_external_monitor()
    if target_monitor is None:
        log.info("No external monitor available for workspace evacuation")
        return

    result = subprocess.run(
        ["hyprctl", "workspaces", "-j"],
        capture_output=True,
        text=True,
        check=True,
    )
    workspaces = json.loads(result.stdout)
    builtin_workspaces = [
        workspace["name"]
        for workspace in workspaces
        if workspace.get("monitor") == BUILTIN_MONITOR
    ]
    if not builtin_workspaces:
        log.info("No workspaces on %s to evacuate", BUILTIN_MONITOR)
        return

    log.info(
        "Moving workspaces off %s onto %s: %s",
        BUILTIN_MONITOR,
        target_monitor,
        ", ".join(builtin_workspaces),
    )
    for workspace_name in builtin_workspaces:
        subprocess.run(
            [
                "hyprctl",
                "dispatch",
                "moveworkspacetomonitor",
                workspace_name,
                target_monitor,
            ],
            check=True,
        )


def restart_waybar() -> None:
    """Restart Waybar after a monitor topology change."""
    log.info("Restarting Waybar to rebind it to the current monitor topology")
    subprocess.run(["pkill", "-x", "waybar"], check=False)
    time.sleep(WAYBAR_RESTART_DELAY)
    subprocess.run(["hyprctl", "dispatch", "exec", "waybar"], check=True)


def enable_builtin() -> None:
    """Restore the built-in display config, power it on, and refresh Waybar."""
    log.info("Enabling %s (laptop mode)", BUILTIN_MONITOR)
    subprocess.run(
        ["hyprctl", "keyword", "monitor", BUILTIN_MONITOR_CONFIG],
        check=True,
    )
    subprocess.run(
        ["hyprctl", "dispatch", "dpms", "on", BUILTIN_MONITOR],
        check=True,
    )
    restart_waybar()


def disable_builtin() -> None:
    """Turn off the built-in display with DPMS and refresh Waybar."""
    evacuate_builtin_workspaces()
    log.info("Turning DPMS off on %s (dock mode)", BUILTIN_MONITOR)
    subprocess.run(
        ["hyprctl", "dispatch", "dpms", "off", BUILTIN_MONITOR],
        check=True,
    )
    restart_waybar()


def notify(summary: str, body: str) -> None:
    """Send a desktop notification; silently skip if notify-send is absent."""
    try:
        subprocess.run(
            [
                "notify-send",
                "--app-name=monitor-hotplug",
                "--urgency=low",
                "--expire-time=4000",
                "--transient",
                summary,
                body,
            ],
            check=False,
        )
    except FileNotFoundError:
        pass


def reconcile_topology(*, notify_user: bool = True) -> None:
    """Examine the current monitor topology and switch modes as needed.

    Four-state decision table:

    builtin_active | externals present | Action
    ---------------+-------------------+-----------------------------
    True           | Yes               | disable_builtin → dock mode
    False          | No                | enable_builtin  → laptop mode
    True           | No                | no-op (already laptop mode)
    False          | Yes               | no-op (dock mode / manual override)
    """
    builtin_active, external_names = get_monitor_state()
    log.info(
        "Current state: builtin_active=%s, externals=%s",
        builtin_active,
        external_names,
    )
    if builtin_active and external_names:
        disable_builtin()
        if notify_user:
            notify(
                "Dock mode",
                f"Switched to external monitors: {', '.join(external_names)}",
            )
    elif not builtin_active and not external_names:
        enable_builtin()
        if notify_user:
            notify("Laptop mode", f"{BUILTIN_MONITOR} re-enabled after dock disconnect")
    else:
        log.info("No mode change needed")


def recover_from_resume() -> None:
    """Recover laptop mode after resume without forcing dock-mode changes.

    This is intentionally asymmetric with ``reconcile_topology``: on resume we
    only re-enable the built-in panel when no external monitors are active.
    That recovers from unplugging while asleep without risking an early dock
    mode switch during resume-time monitor flapping.
    """
    builtin_active, external_names = get_monitor_state()
    log.info(
        "Resume recovery state: builtin_active=%s, externals=%s",
        builtin_active,
        external_names,
    )
    if not builtin_active and not external_names:
        enable_builtin()
        log.info("Resume recovery re-enabled %s", BUILTIN_MONITOR)
    else:
        log.info("Resume recovery not needed")


def settle_and_act() -> None:
    """Run a reconciled monitor mode decision after the debounce delay."""
    try:
        reconcile_topology()
    except Exception:
        log.exception("Error in settle_and_act")


def schedule_settle(reason: str) -> None:
    """Reset the debounce timer; every new topology event postpones the action."""
    global _timer
    with _timer_lock:
        if _timer is not None:
            _timer.cancel()
        _timer = threading.Timer(SETTLE_DELAY, settle_and_act)
        _timer.daemon = True
        _timer.start()
    log.info("Settle timer (re)started after: %s", reason)


def handle_event(line: str) -> None:
    """Process a single event line from the IPC socket."""
    if line.startswith(("monitoradded>>", "monitorremoved>>")):
        log.info("Monitor topology event: %s", line.rstrip())
        schedule_settle(line.rstrip())


def main() -> None:
    """Connect to the Hyprland event socket and process events indefinitely."""
    parser = argparse.ArgumentParser(description="Hyprland monitor hotplug handler")
    parser.add_argument(
        "--reconcile",
        action="store_true",
        help="run one monitor-topology reconciliation pass and exit",
    )
    parser.add_argument(
        "--resume-recover",
        action="store_true",
        help="recover the built-in display after resume if no externals are active",
    )
    parser.add_argument(
        "--laptop-mode",
        action="store_true",
        help="force laptop mode ownership through this script",
    )
    parser.add_argument(
        "--dock-mode",
        action="store_true",
        help="force dock mode ownership through this script",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=0.0,
        help="sleep for N seconds before running one-shot modes",
    )
    args = parser.parse_args()

    if args.delay > 0:
        time.sleep(args.delay)

    if args.reconcile:
        reconcile_topology(notify_user=False)
        return

    if args.resume_recover:
        recover_from_resume()
        return

    if args.laptop_mode:
        enable_builtin()
        return

    if args.dock_mode:
        disable_builtin()
        return

    sock_path = get_socket_path()
    log.info("Connecting to Hyprland event socket: %s", sock_path)

    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                sock.connect(sock_path)
                log.info("Connected")
                buf = ""
                while True:
                    data = sock.recv(4096).decode("utf-8", errors="replace")
                    if not data:
                        log.warning("Socket closed by Hyprland, reconnecting…")
                        break
                    buf += data
                    *lines, buf = buf.split("\n")
                    for line in lines:
                        if line:
                            handle_event(line)
        except (ConnectionRefusedError, FileNotFoundError) as exc:
            log.warning("Could not connect (%s), retrying in 5s…", exc)
            time.sleep(5)
        except Exception as exc:  # noqa: BLE001
            log.error("Unexpected error: %s, retrying in 5s…", exc)
            time.sleep(5)


if __name__ == "__main__":
    main()
