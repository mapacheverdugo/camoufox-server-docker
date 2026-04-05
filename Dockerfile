FROM amazonlinux:2023

# Instalar dependencias del sistema
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
    && dnf clean all

# Crear symlinks para python
RUN ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3.12 /usr/bin/pip3

# Crear usuario no-root
RUN useradd -m -s /bin/bash appuser

USER appuser
ENV PATH="/home/appuser/.local/bin:${PATH}"

# Instalar paquetes de Python como appuser
RUN python3 -m pip install --upgrade pip --user && \
    python3 -m pip install -U camoufox[geoip] "playwright==1.52.0" --user

# Descargar datos de camoufox
RUN python3 -m camoufox fetch

WORKDIR /app
COPY --chown=appuser:appuser main.py .
COPY --chown=appuser:appuser entrypoint.sh .
RUN chmod +x entrypoint.sh

ENV DISPLAY=:99
EXPOSE 1234

ENTRYPOINT ["./entrypoint.sh"]
CMD ["python3", "main.py"]
