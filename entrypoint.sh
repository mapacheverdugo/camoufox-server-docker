#!/bin/bash

# Iniciar Xvfb en display :99
Xvfb :99 -screen 0 1280x720x16 &
sleep 1

# Ejecutar el comando pasado al contenedor
exec "$@"
