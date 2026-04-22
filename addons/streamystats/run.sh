#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/data/streamystats"
PGDATA="${PGDATA:-${DATA_DIR}/postgresql}"
SECRETS_FILE="${DATA_DIR}/secrets.env"

generate_hex() {
  cat /proc/sys/kernel/random/uuid | tr -d '-'
}

mkdir -p "${DATA_DIR}"
mkdir -p "${PGDATA}"

if [ "$(id -u)" = "0" ]; then
  chown -R 999:999 "${DATA_DIR}" "${PGDATA}"
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

# When running as a Home Assistant add-on with ingress enabled, discover the
# real ingress entry path and forward it to Streamystats' basePath support.
if [ -z "${NEXT_PUBLIC_BASE_PATH:-}" ] && [ -n "${SUPERVISOR_TOKEN:-}" ]; then
  ingress_entry="$({
    curl -fsSL \
      -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
      "http://supervisor/addons/self/info" || true;
  } | tr -d '\n' | sed -n 's/.*"ingress_entry":"\([^"]*\)".*/\1/p' | sed 's#\\/#/#g')"

  if [ -n "${ingress_entry}" ]; then
    export NEXT_PUBLIC_BASE_PATH="${ingress_entry}"
    echo "Using detected ingress base path: ${NEXT_PUBLIC_BASE_PATH}"
  fi
fi

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