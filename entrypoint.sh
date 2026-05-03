#!/bin/bash
set -e

# Valores por defecto si no vienen del entorno
: "${DISPLAY:=:99}"
: "${SCREEN_WIDTH:=1280}"
: "${SCREEN_HEIGHT:=720}"
: "${SCREEN_DEPTH:=16}"

# Limpieza de un Xvfb previo si existiera (útil al reiniciar el contenedor)
DISPLAY_NUM="${DISPLAY#:}"
LOCK_FILE="/tmp/.X${DISPLAY_NUM}-lock"
if [ -f "$LOCK_FILE" ]; then
    rm -f "$LOCK_FILE" "/tmp/.X11-unix/X${DISPLAY_NUM}" 2>/dev/null || true
fi

# Iniciar Xvfb en background
Xvfb "$DISPLAY" -screen 0 "${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH}" &
XVFB_PID=$!

# Reenvío de señales para que Xvfb termine limpio al detener el contenedor
trap 'kill -TERM "$XVFB_PID" 2>/dev/null || true' TERM INT

# Pequeña espera para que el display esté disponible
sleep 1

# Ejecutar el comando principal
exec "$@"
