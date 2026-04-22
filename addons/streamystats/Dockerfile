FROM ghcr.io/fredrikburmester/streamystats-aio:v2.18.0

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL io.hass.version="${BUILD_VERSION}" \
  io.hass.type="app" \
  io.hass.arch="${BUILD_ARCH}"

COPY run.sh /run.sh

RUN if command -v apk >/dev/null 2>&1; then \
      apk add --no-cache nginx; \
    elif command -v apt-get >/dev/null 2>&1; then \
      apt-get update && apt-get install -y --no-install-recommends nginx && rm -rf /var/lib/apt/lists/*; \
    else \
      echo "Unsupported base image: no apk/apt-get found" >&2; \
      exit 1; \
    fi \
  && mkdir -p /run/nginx /tmp/nginx \
  && chmod a+rx /run.sh

ENTRYPOINT ["/run.sh"]