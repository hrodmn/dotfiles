#!/usr/bin/env bash
set -euo pipefail

controller_powered() {
    bluetoothctl show 2>/dev/null | grep -q "Powered: yes"
}

connected_devices() {
    bluetoothctl devices Connected 2>/dev/null | sed 's/^Device [^ ]* //'
}

print_status() {
    local icon class tooltip devices device_count

    if ! bluetoothctl show >/dev/null 2>&1; then
        printf '{"text":"󰂲","alt":"unavailable","tooltip":"Bluetooth controller unavailable","class":"unavailable"}\n'
        return
    fi

    if ! controller_powered; then
        printf '{"text":"󰂲","alt":"off","tooltip":"Bluetooth off\nClick to turn on\nRight-click to open Blueman","class":"off"}\n'
        return
    fi

    devices="$(connected_devices)"

    if [ -n "$devices" ]; then
        device_count="$(printf '%s\n' "$devices" | wc -l | tr -d ' ')"
        icon="󰂱"
        class="connected"
        tooltip="Bluetooth on\nConnected (${device_count}):\n${devices}\n\nClick to turn off\nRight-click to open Blueman"
    else
        icon="󰂯"
        class="on"
        tooltip="Bluetooth on\nNo connected devices\nClick to turn off\nRight-click to open Blueman"
    fi

    printf '{"text":"%s","alt":"%s","tooltip":"%s","class":"%s"}\n' \
        "$icon" "$class" "$tooltip" "$class"
}

toggle_power() {
    if controller_powered; then
        bluetoothctl power off >/dev/null
    else
        bluetoothctl power on >/dev/null
    fi
}

case "${1:-status}" in
    status)
        print_status
        ;;
    toggle)
        toggle_power
        ;;
    *)
        printf 'Usage: %s {status|toggle}\n' "$0" >&2
        exit 1
        ;;
esac
