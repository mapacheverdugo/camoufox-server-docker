# Dockerfile
# ACTUALIZADO: Con una solución de permisos explícita y forzada para resolver el error de build.

#
# 1) Base: Python 3.12 on Amazon Linux 2023
#
FROM amazonlinux:2023

<<<<<<< Updated upstream
#
# 2) Instalar dependencias del sistema como ROOT
#
=======
# Build args - pueden sobreescribirse con --build-arg
# Si están vacíos se instala la última versión disponible.
ARG PLAYWRIGHT_VERSION=
ARG CAMOUFOX_VERSION=

# Dependencias del sistema necesarias para Camoufox/Playwright + Xvfb
>>>>>>> Stashed changes
RUN dnf update -y && dnf install -y \
    python3.12 \
    python3.12-pip \
    python3.12-devel \
    xorg-x11-server-Xvfb \
    procps-ng \
    gtk3 \
    libX11 \
    libXcomposite \
    libXcursor \
    libXdamage \
    libXext \
    libXfixes \
    libXi \
    libXtst \
    alsa-lib \
    pango \
    cups-libs \
<<<<<<< Updated upstream
    amazon-efs-utils \
    socat \
    && dnf clean all
=======
    && dnf clean all \
    && rm -rf /var/cache/dnf
>>>>>>> Stashed changes

# Symlinks para que `python3` y `pip3` apunten a 3.12
RUN ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3.12 /usr/bin/pip3

<<<<<<< Updated upstream
#
# 3) Instalar paquetes de Python y descargar datos como ROOT
#
RUN python3 -m pip install --upgrade pip --no-cache-dir && \
    python3 -m pip install -U camoufox[geoip] "playwright==1.52.0" --no-cache-dir

# --- ¡CAMBIO CLAVE! ---
# Forzamos los permisos de escritura en el directorio de destino de la librería
# ANTES de intentar ejecutar el comando de descarga.
RUN chmod -R 777 /usr/local/lib/python3.12/site-packages/camoufox

# Ahora, ejecutamos el fetch como ROOT. Con los permisos explícitamente establecidos,
# la escritura del archivo .mmdb no debería fallar.
RUN python3 -m camoufox fetch

#
# 4) Preparar el entorno para el usuario no-root
#
# Crear el usuario no-root
RUN useradd -m -s /bin/bash appuser

# Cambiar al directorio de la aplicación
WORKDIR /app

# Copiar el código de la aplicación y darle permisos al usuario no-root
COPY --chown=appuser:appuser main.py .
COPY --chown=appuser:appuser entrypoint.sh .
RUN chmod +x entrypoint.sh

#
# 5) Configuración final y cambio a usuario no-root
#
ENV DISPLAY=:99
EXPOSE 1234
# Dockerfile
# ACTUALIZADO: Con una estrategia de instalación de usuario para resolver
# el error de permisos de forma definitiva.

#
# 1) Base: Python 3.12 on Amazon Linux 2023
#
FROM amazonlinux:2023

#
# 2) Instalar dependencias del sistema como ROOT
#
RUN dnf update -y && dnf install -y \
    python3.12 \
    python3.12-pip \
    python3.12-devel \
    xorg-x11-server-Xvfb \
    gtk3 \
    libX11 \
    libXcomposite \
    libXcursor \
    libXdamage \
    libXext \
    libXfixes \
    libXi \
    libXtst \
    alsa-lib \
    pango \
    cups-libs \
    amazon-efs-utils \
    && dnf clean all

# Crear symlinks para python
RUN ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3.12 /usr/bin/pip3

#
# 3) Preparar el entorno para el usuario no-root
#
# Crear el usuario no-root
RUN useradd -m -s /bin/bash appuser

# Cambiar al usuario no-root
=======
# Usuario no-root
RUN useradd -m -s /bin/bash appuser
>>>>>>> Stashed changes
USER appuser

# --- ¡CAMBIO CLAVE! ---
# Añadimos el directorio local del usuario al PATH del sistema.
ENV PATH="/home/appuser/.local/bin:${PATH}"

<<<<<<< Updated upstream
#
# 4) Instalar paquetes de Python y descargar datos como 'appuser'
#
# Actualizamos pip e instalamos los paquetes con el flag --user.
# Esto los instala en el directorio home del usuario, evitando problemas de permisos.
=======
# Instalar paquetes Python. Si las versiones están vacías se usa la última.
>>>>>>> Stashed changes
RUN python3 -m pip install --upgrade pip --user && \
    if [ -n "$PLAYWRIGHT_VERSION" ]; then \
        PW_SPEC="playwright==${PLAYWRIGHT_VERSION}"; \
    else \
        PW_SPEC="playwright"; \
    fi && \
    if [ -n "$CAMOUFOX_VERSION" ]; then \
        CF_SPEC="camoufox[geoip]==${CAMOUFOX_VERSION}"; \
    else \
        CF_SPEC="camoufox[geoip]"; \
    fi && \
    python3 -m pip install -U "$CF_SPEC" "$PW_SPEC" --user

<<<<<<< Updated upstream
# Ahora, ejecutamos el fetch como 'appuser'. Los datos se guardarán en el
# directorio home del usuario, donde tiene plenos permisos.
=======
# Pre-descargar el binario de Camoufox (queda en cache de la imagen)
>>>>>>> Stashed changes
RUN python3 -m camoufox fetch

#
# 5) Configuración final de la aplicación
#
WORKDIR /app
COPY --chown=appuser:appuser main.py .
COPY --chown=appuser:appuser entrypoint.sh .
RUN chmod +x entrypoint.sh

ENV DISPLAY=:99 \
    SCREEN_WIDTH=1280 \
    SCREEN_HEIGHT=720 \
    SCREEN_DEPTH=16 \
    PORT=1234

EXPOSE 1234

ENTRYPOINT ["./entrypoint.sh"]
CMD ["python3", "main.py"]

# Cambiamos al usuario no-root al final, justo antes de ejecutar la aplicación.
USER appuser

ENTRYPOINT ["./entrypoint.sh"]
CMD ["python3", "main.py"]
