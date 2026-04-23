# Dockerfile für Home Assistant Addon: NZBHydra2 + Gluetun (WireGuard)
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.19
FROM ${BUILD_FROM}

# Install Gluetun und NZBHydra2
RUN apk add --no-cache wireguard-tools curl bash

# Gluetun
ENV GLUETUN_VERSION=latest
RUN mkdir -p /gluetun && \
    wget -O /gluetun/gluetun.tar.gz https://github.com/qdm12/gluetun/releases/latest/download/gluetun_linux_amd64.tar.gz && \
    tar -xzf /gluetun/gluetun.tar.gz -C /gluetun && \
    chmod +x /gluetun/gluetun

# NZBHydra2
ENV NZBHYDRA2_VERSION=latest
RUN mkdir -p /nzbhydra2
RUN wget -O /nzbhydra2/nzbhydra2.tar.gz https://lscr.io/linuxserver/nzbhydra2/download/latest && \
    tar -xzf /nzbhydra2/nzbhydra2.tar.gz -C /nzbhydra2 || true

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
