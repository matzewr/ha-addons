#!/usr/bin/env bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"
STACK_DIR="/tmp/nzbhydra2-vpn-stack"
COMPOSE_FILE="${STACK_DIR}/docker-compose.yaml"
BASE_CONFIG_DIR="/addon_config"
GLUETUN_CONFIG_DIR="${BASE_CONFIG_DIR}/gluetun"
NZBHYDRA2_CONFIG_DIR="${BASE_CONFIG_DIR}/nzbhydra2"
WG_CONFIG_FILE="${GLUETUN_CONFIG_DIR}/wg0.conf"

if [[ ! -f "${OPTIONS_FILE}" ]]; then
  echo "[ERROR] ${OPTIONS_FILE} not found"
  exit 1
fi

TZ_VALUE="$(jq -r '.TZ // "UTC"' "${OPTIONS_FILE}")"
WEBUI_PORT="$(jq -r '.WEBUI_PORT // 5076' "${OPTIONS_FILE}")"
SERVER_COUNTRIES="$(jq -r '.SERVER_COUNTRIES // ""' "${OPTIONS_FILE}")"

mkdir -p "${STACK_DIR}" \
         "${GLUETUN_CONFIG_DIR}" \
         "${NZBHYDRA2_CONFIG_DIR}"

if [[ ! -f "${WG_CONFIG_FILE}" ]]; then
  echo "[ERROR] WireGuard config not found: ${WG_CONFIG_FILE}"
  echo "[ERROR] Lege die Datei wg0.conf in ${GLUETUN_CONFIG_DIR} ab."
  exit 1
fi

cat > "${COMPOSE_FILE}" <<EOF
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: ha-nzbhydra2-gluetun
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - TZ=${TZ_VALUE}
      - VPN_SERVICE_PROVIDER=custom
      - VPN_TYPE=wireguard
      - FIREWALL_VPN_INPUT_PORTS=${WEBUI_PORT}
    volumes:
      - ${GLUETUN_CONFIG_DIR}:/gluetun
    ports:
      - "${WEBUI_PORT}:5076"

  nzbhydra2:
    image: lscr.io/linuxserver/nzbhydra2:latest
    container_name: ha-nzbhydra2-app
    restart: unless-stopped
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    environment:
      - TZ=${TZ_VALUE}
      - PUID=0
      - PGID=0
    volumes:
      - ${NZBHYDRA2_CONFIG_DIR}:/config
EOF

echo "[INFO] Starting Gluetun + NZBHydra2 stack"
exec docker compose -f "${COMPOSE_FILE}" up --remove-orphans
