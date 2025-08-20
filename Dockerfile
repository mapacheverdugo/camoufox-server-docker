#
# 1) Base: Python 3.12 on Amazon Linux 2023
#
FROM amazonlinux:2023

#
# 2) Install Python and system dependencies
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
    && dnf clean all

# Create symlinks for python3 and pip3
RUN ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3.12 /usr/bin/pip3

# Create a non-root user
RUN useradd -m -s /bin/bash appuser

# Set working directory
WORKDIR /app

#
# 3) Upgrade pip and install Camoufox[geoip]
#
RUN python3 -m pip install --upgrade pip \
 && python3 -m pip install -U camoufox[geoip] "playwright==1.52.0"

RUN python3 -m camoufox fetch

# Set display environment variable
ENV DISPLAY=:99

# Expose WebSocket port
EXPOSE 1234

# Copy application code and entrypoint script
COPY main.py .
COPY entrypoint.sh .

# Make the entrypoint script executable
RUN chmod +x entrypoint.sh

# Switch to non-root user
USER appuser

# Set the entrypoint
ENTRYPOINT ["./entrypoint.sh"]

# Run the application
CMD ["python3", "main.py"]