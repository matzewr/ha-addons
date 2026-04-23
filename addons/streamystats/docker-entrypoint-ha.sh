#!/usr/bin/env bash
set -e

# Load Home Assistant add-on options when present.
if [ -f /data/options.json ]; then
	POSTGRES_USER="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync("/data/options.json","utf8"));process.stdout.write(o.POSTGRES_USER||"postgres")')"
	POSTGRES_PASSWORD="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync("/data/options.json","utf8"));process.stdout.write(o.POSTGRES_PASSWORD||"postgres")')"
	POSTGRES_DB="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync("/data/options.json","utf8"));process.stdout.write(o.POSTGRES_DB||"streamystats")')"
	SESSION_SECRET="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync("/data/options.json","utf8"));process.stdout.write(o.SESSION_SECRET||"supersecret")')"
	NEXT_SERVER_ACTIONS_ENCRYPTION_KEY="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync("/data/options.json","utf8"));process.stdout.write(o.NEXT_SERVER_ACTIONS_ENCRYPTION_KEY||"supersecretkey")')"
else
	POSTGRES_USER="${POSTGRES_USER:-postgres}"
	POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
	POSTGRES_DB="${POSTGRES_DB:-streamystats}"
	SESSION_SECRET="${SESSION_SECRET:-supersecret}"
	NEXT_SERVER_ACTIONS_ENCRYPTION_KEY="${NEXT_SERVER_ACTIONS_ENCRYPTION_KEY:-supersecretkey}"
fi

export POSTGRES_USER
export POSTGRES_PASSWORD
export POSTGRES_DB
export SESSION_SECRET
export NEXT_SERVER_ACTIONS_ENCRYPTION_KEY
export DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}"

# Prepare persistent PGDATA in Home Assistant's /data mount before supervisor starts.
mkdir -p /data/pgdata
chown -R postgres:postgres /data/pgdata
chmod 700 /data/pgdata || true

exec /app/entrypoint.sh
