#!/usr/bin/env bash
set -euo pipefail

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-power-profile.log"

log() {
    mkdir -p "$(dirname "$log_file")"
    printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$log_file"
}

current_profile() {
    powerprofilesctl get 2>/dev/null || printf 'balanced\n'
}

on_ac_power() {
    local supply type

    for supply in /sys/class/power_supply/*; do
        [ -e "$supply/type" ] || continue
        type="$(<"$supply/type")"
        if [ "$type" = "Mains" ] && [ -e "$supply/online" ] && [ "$(<"$supply/online")" = "1" ]; then
            return 0
        fi
    done

    return 1
}

print_status() {
    local profile icon class text tooltip

    if on_ac_power; then
        exit 0
    fi

    profile="$(current_profile)"

    case "$profile" in
        power-saver)
            icon=""
            class="powersave"
            text="Saver"
            tooltip="Power profile: power-saver\nClick to switch to balanced"
            ;;
        performance)
            icon="󱐋"
            class="performance"
            text="Perf"
            tooltip="Power profile: performance\nClick to switch to power-saver"
            ;;
        *)
            icon="󰾆"
            class="balanced"
            text="Balanced"
            tooltip="Power profile: balanced\nClick to switch to power-saver"
            ;;
    esac

    printf '{"text":"%s %s","alt":"%s","tooltip":"%s","class":"%s"}\n' \
        "$icon" "$text" "$profile" "$tooltip" "$class"
}

set_profile() {
    local target="$1"
    log "setting profile to $target"
    powerprofilesctl set "$target"
    log "profile is now $(current_profile)"
}

restart_waybar() {
    log "restarting waybar"
    (
        sleep 0.2
        pkill waybar || true
        nohup waybar >/dev/null 2>&1 </dev/null &
    ) >/dev/null 2>&1 &
}

case "${1:-status}" in
    status)
        print_status
        ;;
    toggle)
        log "toggle requested; current=$(current_profile)"
        case "$(current_profile)" in
            power-saver) set_profile balanced ;;
            *) set_profile power-saver ;;
        esac
        restart_waybar
        ;;
    *)
        printf 'Usage: %s {status|toggle}\n' "$0" >&2
        exit 1
        ;;
esac
