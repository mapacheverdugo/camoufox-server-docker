#!/bin/bash
echo "ENTRYPOINT START: $(date +%s.%N)"

# Function to cleanup Xvfb processes
cleanup_xvfb() {
    echo "Cleaning up Xvfb processes..."
    pkill -f "Xvfb :99" 2>/dev/null || true
    rm -f /tmp/.X99-lock
}

# Set up trap to cleanup on exit
trap cleanup_xvfb EXIT

# Clean up any existing X11 lock files and processes
cleanup_xvfb

# Check if Xvfb is already running on display :99
if ! pgrep -f "Xvfb :99" > /dev/null; then
    echo "Starting Xvfb server on display :99..."
    # Inicia el servidor Xvfb en el display :99 y en segundo plano (&)
    Xvfb :99 -screen 0 1280x720x16 &
    # Give Xvfb time to start
    sleep 2
else
    echo "Xvfb server already running on display :99"
fi

# Get port from environment variable, default to 1234
PORT=${PORT:-1234}
echo "Iniciando proxy TCP en el puerto $PORT..."
socat TCP4-LISTEN:$PORT,fork TCP:127.0.0.1:$PORT &

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