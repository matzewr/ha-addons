# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
FROM ghcr.io/fredrikburmester/streamystats-aio:latest

ENV PGDATA=/data
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=streamystats
ENV DATABASE_URL=postgresql://${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD:-postgres}@localhost:5432/${POSTGRES_DB:-streamystats}
ENV SESSION_SECRET=supersecret
ENV NEXT_SERVER_ACTIONS_ENCRYPTION_KEY=supersecretkey

# Override original entrypoint
ENTRYPOINT ["./app/entrypoint.sh"]