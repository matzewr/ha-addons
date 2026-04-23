#!/usr/bin/env bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"
STACK_DIR="/tmp/nzbhydra2-vpn-stack"
COMPOSE_FILE="${STACK_DIR}/docker-compose.yaml"
CONTAINER_CONFIG_DIR="/config"
CONTAINER_GLUETUN_CONFIG_DIR="${CONTAINER_CONFIG_DIR}/gluetun"
CONTAINER_NZBHYDRA2_CONFIG_DIR="${CONTAINER_CONFIG_DIR}/nzbhydra2"
WG_CONFIG_FILE="${CONTAINER_GLUETUN_CONFIG_DIR}/wg0.conf"
GLUETUN_VOLUME_NAME="ha_nzbhydra2_vpn_gluetun"
NZBHYDRA2_VOLUME_NAME="ha_nzbhydra2_vpn_nzbhydra2"

sync_dir_to_volume() {
  local source_dir="$1"
  local volume_name="$2"
  local temp_container

  docker volume create "${volume_name}" >/dev/null
  temp_container="$(docker create -v "${volume_name}:/target" alpine:3.20 sh -c 'sleep 300')"

  # Copy the add-on config directory into the Docker volume via API.
  docker cp "${source_dir}/." "${temp_container}:/target/"
  docker rm "${temp_container}" >/dev/null
}

if [[ ! -f "${OPTIONS_FILE}" ]]; then
  echo "[ERROR] ${OPTIONS_FILE} not found"
  exit 1
fi

TZ_VALUE="$(jq -r '.TZ // "UTC"' "${OPTIONS_FILE}")"
WEBUI_PORT="$(jq -r '.WEBUI_PORT // 5076' "${OPTIONS_FILE}")"
SERVER_COUNTRIES="$(jq -r '.SERVER_COUNTRIES // ""' "${OPTIONS_FILE}")"

mkdir -p "${STACK_DIR}" \
         "${CONTAINER_GLUETUN_CONFIG_DIR}" \
         "${CONTAINER_NZBHYDRA2_CONFIG_DIR}"

if [[ ! -f "${WG_CONFIG_FILE}" ]]; then
  echo "[ERROR] WireGuard config not found: ${WG_CONFIG_FILE}"
  echo "[ERROR] Lege die Datei wg0.conf in ${CONTAINER_GLUETUN_CONFIG_DIR} ab."
  exit 1
fi

echo "[INFO] Synchronizing ${CONTAINER_GLUETUN_CONFIG_DIR} to Docker volume ${GLUETUN_VOLUME_NAME}"
sync_dir_to_volume "${CONTAINER_GLUETUN_CONFIG_DIR}" "${GLUETUN_VOLUME_NAME}"

if [[ -n "$(ls -A "${CONTAINER_NZBHYDRA2_CONFIG_DIR}" 2>/dev/null || true)" ]]; then
  echo "[INFO] Synchronizing ${CONTAINER_NZBHYDRA2_CONFIG_DIR} to Docker volume ${NZBHYDRA2_VOLUME_NAME}"
  sync_dir_to_volume "${CONTAINER_NZBHYDRA2_CONFIG_DIR}" "${NZBHYDRA2_VOLUME_NAME}"
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
      - ${GLUETUN_VOLUME_NAME}:/gluetun
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
      - ${NZBHYDRA2_VOLUME_NAME}:/config

volumes:
  ${GLUETUN_VOLUME_NAME}:
    name: ${GLUETUN_VOLUME_NAME}
  ${NZBHYDRA2_VOLUME_NAME}:
    name: ${NZBHYDRA2_VOLUME_NAME}
EOF

echo "[INFO] Starting Gluetun + NZBHydra2 stack"
exec docker compose -f "${COMPOSE_FILE}" up --remove-orphans
