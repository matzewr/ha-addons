FROM lscr.io/linuxserver/nzbhydra2:latest

USER root

COPY --from=ghcr.io/qdm12/gluetun:latest /gluetun-entrypoint /usr/local/bin/gluetun-entrypoint

COPY --chmod=755 run.sh /run.sh

ENTRYPOINT ["/run.sh"]
