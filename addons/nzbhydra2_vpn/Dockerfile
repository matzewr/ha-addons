FROM lscr.io/linuxserver/nzbhydra2:latest

USER root

COPY --from=ghcr.io/qdm12/gluetun:latest /gluetun-entrypoint /usr/local/bin/gluetun-entrypoint

RUN chmod +x /usr/local/bin/gluetun-entrypoint \
	&& if command -v apk >/dev/null 2>&1; then \
		apk add --no-cache jq iproute2; \
	elif command -v apt-get >/dev/null 2>&1; then \
		export DEBIAN_FRONTEND=noninteractive; \
		apt-get update; \
		apt-get install -y --no-install-recommends jq iproute2; \
		rm -rf /var/lib/apt/lists/*; \
	else \
		echo "No supported package manager found"; \
		exit 1; \
	fi

COPY --chmod=755 run.sh /run.sh

ENTRYPOINT ["/run.sh"]
