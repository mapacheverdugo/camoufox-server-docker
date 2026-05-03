#!/bin/bash
set -e

# Defaults if not provided via environment
: "${ENABLE_XVFB:=true}"
: "${DISPLAY:=:99}"
: "${SCREEN_WIDTH:=1280}"
: "${SCREEN_HEIGHT:=720}"
: "${SCREEN_DEPTH:=16}"

case "${ENABLE_XVFB,,}" in
    1|true|yes|on)
        # Clean up a previous Xvfb lockfile if present (useful on container restart)
        DISPLAY_NUM="${DISPLAY#:}"
        LOCK_FILE="/tmp/.X${DISPLAY_NUM}-lock"
        if [ -f "$LOCK_FILE" ]; then
            rm -f "$LOCK_FILE" "/tmp/.X11-unix/X${DISPLAY_NUM}" 2>/dev/null || true
        fi

        # Start Xvfb in the background
        Xvfb "$DISPLAY" -screen 0 "${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH}" &
        XVFB_PID=$!

        # Forward signals so Xvfb terminates cleanly when the container stops
        trap 'kill -TERM "$XVFB_PID" 2>/dev/null || true' TERM INT

        # Small wait so the display is ready before the main process starts
        sleep 1
        ;;
    *)
        echo "ENABLE_XVFB=${ENABLE_XVFB} -> skipping Xvfb startup"
        # Camoufox will need to run headless when no display is available;
        # main.py reads ENABLE_XVFB and forces headless mode in that case.
        unset DISPLAY
        ;;
esac

# Run the main command
exec "$@"
