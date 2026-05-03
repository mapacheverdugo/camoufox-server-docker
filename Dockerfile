FROM amazonlinux:2023

# Build args - pueden sobreescribirse con --build-arg.
# Si están vacíos se instala la última versión disponible en PyPI.
ARG PLAYWRIGHT_VERSION=
ARG CAMOUFOX_VERSION=

# Dependencias del sistema necesarias para Camoufox/Playwright + Xvfb
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
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Symlinks para que `python3` y `pip3` apunten a 3.12
RUN ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3.12 /usr/bin/pip3

# Usuario no-root
RUN useradd -m -s /bin/bash appuser
USER appuser
ENV PATH="/home/appuser/.local/bin:${PATH}"

# Instalar paquetes Python como appuser (--user evita problemas de permisos).
# Si las versiones están vacías se usa la última.
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

# Pre-descargar el binario de Camoufox (queda cacheado en la imagen)
RUN python3 -m camoufox fetch

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
