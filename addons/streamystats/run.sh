#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/data/streamystats"
PERSISTENT_PGDATA="${DATA_DIR}/postgresql"
RUNTIME_PGDATA="/var/lib/postgresql/data"
PGDATA="${PGDATA:-${PERSISTENT_PGDATA}}"
SECRETS_FILE="${DATA_DIR}/secrets.env"

generate_hex() {
  cat /proc/sys/kernel/random/uuid | tr -d '-'
}

mkdir -p "${DATA_DIR}"
mkdir -p "${PERSISTENT_PGDATA}"

# One-time migration helper: if old data exists only in runtime location,
# copy it into persistent storage without touching mounted runtime paths.
if [ "${RUNTIME_PGDATA}" != "${PERSISTENT_PGDATA}" ] \
  && [ -d "${RUNTIME_PGDATA}" ] \
  && [ -n "$(ls -A "${RUNTIME_PGDATA}" 2>/dev/null)" ] \
  && [ -z "$(ls -A "${PERSISTENT_PGDATA}" 2>/dev/null)" ]; then
  cp -a "${RUNTIME_PGDATA}/." "${PERSISTENT_PGDATA}/"
fi

if [ "$(id -u)" = "0" ]; then
  chown -R 999:999 "${DATA_DIR}" "${PERSISTENT_PGDATA}"
fi

if [ ! -f "${SECRETS_FILE}" ]; then
  umask 077
  cat >"${SECRETS_FILE}" <<EOF
SESSION_SECRET=$(generate_hex)$(generate_hex)
NEXT_SERVER_ACTIONS_ENCRYPTION_KEY=$(generate_hex)
POSTGRES_PASSWORD=$(generate_hex)$(generate_hex)
EOF
fi

# shellcheck disable=SC1090
set -a
. "${SECRETS_FILE}"
set +a

export NODE_ENV="${NODE_ENV:-production}"
export HOSTNAME="${HOSTNAME:-0.0.0.0}"
export PORT="${PORT:-3000}"

mkdir -p /run/nginx /tmp/nginx

cat >/tmp/nginx/nginx.conf <<'EOF'
worker_processes 1;

events {
  worker_connections 1024;
}

http {
  map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
  }

  server {
    listen 8099;
    server_name _;

    proxy_hide_header X-Frame-Options;

    # Home Assistant ingress requests are prefixed with:
    # /api/hassio_ingress/<token>/...
    # Strip that prefix so the upstream app sees plain routes (/setup, /api/*, ...).
    location ~ ^/api/hassio_ingress/[^/]+$ {
      return 302 /;
    }

    location ~ ^/api/hassio_ingress/[^/]+/(.*)$ {
      rewrite ^/api/hassio_ingress/[^/]+/(.*)$ /$1 break;
      proxy_http_version 1.1;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
      proxy_pass http://127.0.0.1:3000;
    }

    location / {
      proxy_http_version 1.1;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
      proxy_pass http://127.0.0.1:3000;
    }
  }
}
EOF

nginx -c /tmp/nginx/nginx.conf

export JOB_SERVER_URL="${JOB_SERVER_URL:-http://localhost:3005}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_DB="${POSTGRES_DB:-streamystats}"
export POSTGRES_PASSWORD
export SESSION_SECRET
export NEXT_SERVER_ACTIONS_ENCRYPTION_KEY
export POSTGRES_HOST_AUTH_METHOD="${POSTGRES_HOST_AUTH_METHOD:-scram-sha-256}"
export POSTGRES_INITDB_ARGS="${POSTGRES_INITDB_ARGS:---auth-host=scram-sha-256}"
# Always rebuild DATABASE_URL from current credentials so migrations and app use the same DB password.
export DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}"
export PGDATA

exec /app/entrypoint.sh