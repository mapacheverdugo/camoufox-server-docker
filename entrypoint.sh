#!/bin/bash
# Inicia el servidor Xvfb en el display :99 y en segundo plano (&)
Xvfb :99 -screen 0 1280x720x16 &

# Ejecuta el comando que se pasó al contenedor
# (en tu caso, será "python3", "main.py")
exec "$@"