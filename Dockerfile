#
# SIGNAL Dockerfile
#
# https://github.com/annegerben/docker-SIGNAL
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG SIGNAL_VERSION=0.81

# Define software download URLs.
ARG SIGNAL_URL=

# Get Dockerfile cross-compilation helpers.
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

# Build SIGNAL.
FROM --platform=$BUILDPLATFORM alpine:3.18 AS SIGNAL
ARG TARGETPLATFORM
ARG SIGNAL_URL
COPY --from=xx / /
COPY src/SIGNAL /build
RUN /build/build.sh "$SIGNAL_URL"
RUN xx-verify \

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.18-v4.6.3

ARG SIGNAL_VERSION
ARG DOCKER_IMAGE_VERSION

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN add-pkg \
        wget \  
        gpg \
        libgbm1 \
        procps \
        adwaita-icon-theme \
        # A font is needed.
        ttf-dejavu

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Signal_ultramarine_icon.svg/600px-Signal_ultramarine_icon.svg.png && \
    install_app_icon.sh "$APP_ICON_URL"

RUN
    # 1. Install our official public software signing key
    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg && \
    cat signal-desktop-keyring.gpg | tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null && \
    # 2. Add our repository to your list of repositories
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | tee -a /etc/apt/sources.list.d/signal-xenial.list && \
    # 3. Update your package database and install signal
    add-pkg install signal-desktop && \
    # Cleanup
    add-pkg autoremove && \
    rm -rf /var/lib/apt/lists/*

# Post-requirements for Signal
RUN chown root:root /opt/Signal/chrome-sandbox && chmod 4755 /opt/Signal/chrome-sandbox    

# Add files.
COPY rootfs/ /
COPY --from=SIGNAL /tmp/SIGNAL-install/usr/bin /usr/bin

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "SIGNAL" && \
    set-cont-env APP_VERSION "$SIGNAL_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

VOLUME ["/config"]    

# Metadata.
LABEL \
      org.label-schema.name="SIGNAL" \
      org.label-schema.description="Docker container for SIGNAL" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/annegerben/docker-SIGNAL" \
      org.label-schema.schema-version="1.0"


