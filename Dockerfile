FROM amazonlinux:2023

# Build args - override with --build-arg.
# If empty, the latest version available on PyPI is installed.
ARG PLAYWRIGHT_VERSION=
ARG CAMOUFOX_VERSION=

# System dependencies required by Camoufox/Playwright + Xvfb
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

# Make `python3` and `pip3` point to 3.12
RUN ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3.12 /usr/bin/pip3

# Pre-create the X11 socket directory with the canonical permissions
# (root-owned, sticky, 1777) so Xvfb does not warn about wrong ownership.
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

# Non-root user
RUN useradd -m -s /bin/bash appuser
USER appuser
ENV PATH="/home/appuser/.local/bin:${PATH}"

# Install Python packages as appuser (--user avoids permission issues).
# If versions are empty, latest is installed.
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

# Pre-fetch the Camoufox binary (cached in the image layer)
RUN python3 -m camoufox fetch

WORKDIR /app
COPY --chown=appuser:appuser main.py .
COPY --chown=appuser:appuser entrypoint.sh .
RUN chmod +x entrypoint.sh

ENV DISPLAY=:99 \
    SCREEN_WIDTH=1280 \
    SCREEN_HEIGHT=720 \
    SCREEN_DEPTH=16

EXPOSE 1234

ENTRYPOINT ["./entrypoint.sh"]
CMD ["python3", "main.py"]
