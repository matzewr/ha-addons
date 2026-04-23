# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
FROM ghcr.io/fredrikburmester/streamystats-aio:latest

# Home Assistant add-on persistent storage is mounted at /data.
ENV PGDATA=/data/pgdata
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=streamystats
ENV DATABASE_URL=postgresql://postgres:postgres@localhost:5432/streamystats
ENV SESSION_SECRET=supersecret
ENV NEXT_SERVER_ACTIONS_ENCRYPTION_KEY=supersecretkey

COPY docker-entrypoint-ha.sh /usr/local/bin/docker-entrypoint-ha.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-ha.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-ha.sh"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
	CMD curl -fsS http://127.0.0.1:3000/api/health \
	&& curl -fsS http://127.0.0.1:3005/health \
	&& pg_isready -h localhost -U ${POSTGRES_USER} -d ${POSTGRES_DB} \
	|| exit 1