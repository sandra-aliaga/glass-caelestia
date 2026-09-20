#!/bin/bash
# super-launcher.sh
# Llamar con "press" cuando Super se presiona, "release" cuando se suelta,
# "interrupt" cuando se presiona otra tecla mientras Super está held.

STATE_FILE="/tmp/hypr-super-launcher-state"

case "$1" in
    press)
        echo "active" > "$STATE_FILE"
        ;;
    interrupt)
        echo "interrupted" > "$STATE_FILE"
        ;;
    release)
        if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "active" ]; then
            WAYLAND_DISPLAY=wayland-1 qs -c caelestia ipc call drawers toggle launcher
        fi
        rm -f "$STATE_FILE"
        ;;
esac
