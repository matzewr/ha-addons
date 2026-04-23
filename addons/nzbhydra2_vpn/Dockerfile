FROM lscr.io/linuxserver/nzbhydra2:latest

USER root

COPY --from=ghcr.io/qdm12/gluetun:latest /gluetun-entrypoint /usr/local/bin/gluetun-entrypoint

RUN apt-get update \
	&& apt-get install -y --no-install-recommends iptables \
	&& rm -rf /var/lib/apt/lists/*

COPY --chmod=755 cont-init-wireguard.sh /etc/cont-init.d/10-wireguard-config
COPY --chmod=755 svc-gluetun-run.sh /etc/s6-overlay/s6-rc.d/svc-gluetun/run
COPY --chmod=755 gluetun-ready.sh /usr/local/bin/gluetun-ready.sh
COPY svc-gluetun-type /etc/s6-overlay/s6-rc.d/svc-gluetun/type
COPY svc-gluetun-notification-fd /etc/s6-overlay/s6-rc.d/svc-gluetun/notification-fd
COPY svc-gluetun-init-services /etc/s6-overlay/s6-rc.d/svc-gluetun/dependencies.d/init-services
COPY svc-gluetun-enabled /etc/s6-overlay/s6-rc.d/user2/contents.d/svc-gluetun
COPY svc-nzbhydra2-dep /etc/s6-overlay/s6-rc.d/svc-nzbhydra2/dependencies.d/svc-gluetun

ENTRYPOINT ["/init"]
