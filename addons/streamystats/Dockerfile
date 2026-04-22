FROM ghcr.io/fredrikburmester/streamystats-aio:v2.18.0

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL io.hass.version="${BUILD_VERSION}" \
  io.hass.type="app" \
  io.hass.arch="${BUILD_ARCH}"

COPY run.sh /run.sh

RUN chmod a+rx /run.sh

ENTRYPOINT ["/run.sh"]