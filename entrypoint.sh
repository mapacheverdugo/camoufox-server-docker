#!/bin/bash
<<<<<<< Updated upstream
echo "ENTRYPOINT START: $(date +%s.%N)"

# Inicia el servidor Xvfb en el display :99 y en segundo plano (&)
Xvfb :99 -screen 0 1280x720x16 &

echo "Iniciando proxy TCP en el puerto 1234..."
socat TCP4-LISTEN:1234,fork TCP:127.0.0.1:1234 &

# Da un pequeño respiro para que el proxy se inicie
sleep 1

if [ -n "$CAMOUFOX_DATA_PATH" ]; then
    echo "CAMOUFOX_DATA_PATH detectado. Copiando datos desde EFS..."
    
    # Define la ruta de destino por defecto de Camoufox
    DEST_PATH="/home/appuser/.cache/camoufox"
    
    # Crea el directorio de destino si no existe
    mkdir -p "$DEST_PATH"
    
    # Copia el contenido desde el volumen EFS a la ruta local del contenedor.
    # El -R copia directorios recursivamente, y el -v te da un output verboso en los logs.
    cp -R "$CAMOUFOX_DATA_PATH"/* "$DEST_PATH"/
    
    echo "Copia desde EFS completada."
fi

# Ejecuta el comando que se pasó al contenedor
# (en tu caso, será "python3", "main.py")
exec "$@"
=======
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
>>>>>>> Stashed changes
