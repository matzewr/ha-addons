FROM ghcr.io/fredrikburmester/streamystats-aio:latest

# Set environment variables
ENV POSTGRES_USER=postgres \
    POSTGRES_PASSWORD=postgres \
    POSTGRES_DB=streamystats \
    POSTGRES_HOST_AUTH_METHOD=scram-sha-256 \
    POSTGRES_INITDB_ARGS=--auth-host=scram-sha-256 \
    DATABASE_URL=postgresql://postgres:postgres@localhost:5432/streamystats \
    SESSION_SECRET=your-session-secret \
    NEXT_SERVER_ACTIONS_ENCRYPTION_KEY=your-encryption-key \
    NODE_ENV=production

# Expose port
EXPOSE 3000

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]