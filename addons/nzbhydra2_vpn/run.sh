#!/usr/bin/env bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"
STACK_DIR="/tmp/nzbhydra2-vpn-stack"
COMPOSE_FILE="${STACK_DIR}/docker-compose.yaml"
CONTAINER_CONFIG_DIR="/config"
CONTAINER_GLUETUN_CONFIG_DIR="${CONTAINER_CONFIG_DIR}/gluetun"
CONTAINER_NZBHYDRA2_CONFIG_DIR="${CONTAINER_CONFIG_DIR}/nzbhydra2"
WG_CONFIG_FILE="${CONTAINER_GLUETUN_CONFIG_DIR}/wg0.conf"

detect_host_config_dir() {
  # Docker daemon resolves bind mounts on the host, not inside this add-on container.
  local mount_root
  mount_root="$(awk '$5 == "/config" { print $4; exit }' /proc/self/mountinfo || true)"

  if [[ -n "${mount_root}" && "${mount_root}" == /* ]]; then
    echo "${mount_root}"
    return 0
  fi

  # Fallback used by Home Assistant for addon_config storage.
  echo "/addon_configs/nzbhydra2_vpn"
}

if [[ ! -f "${OPTIONS_FILE}" ]]; then
  echo "[ERROR] ${OPTIONS_FILE} not found"
  exit 1
fi

TZ_VALUE="$(jq -r '.TZ // "UTC"' "${OPTIONS_FILE}")"
WEBUI_PORT="$(jq -r '.WEBUI_PORT // 5076' "${OPTIONS_FILE}")"
SERVER_COUNTRIES="$(jq -r '.SERVER_COUNTRIES // ""' "${OPTIONS_FILE}")"
HOST_CONFIG_DIR="$(detect_host_config_dir)"
HOST_GLUETUN_CONFIG_DIR="${HOST_CONFIG_DIR}/gluetun"
HOST_NZBHYDRA2_CONFIG_DIR="${HOST_CONFIG_DIR}/nzbhydra2"

mkdir -p "${STACK_DIR}" \
         "${HOST_GLUETUN_CONFIG_DIR}" \
         "${HOST_NZBHYDRA2_CONFIG_DIR}"

if [[ ! -f "${WG_CONFIG_FILE}" ]]; then
  echo "[ERROR] WireGuard config not found: ${WG_CONFIG_FILE}"
  echo "[ERROR] Lege die Datei wg0.conf in ${CONTAINER_GLUETUN_CONFIG_DIR} ab."
  exit 1
fi

echo "[INFO] Host config directory for Docker bind mounts: ${HOST_CONFIG_DIR}"

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
      - ${HOST_GLUETUN_CONFIG_DIR}:/gluetun
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
      - ${HOST_NZBHYDRA2_CONFIG_DIR}:/config
EOF

echo "[INFO] Starting Gluetun + NZBHydra2 stack"
exec docker compose -f "${COMPOSE_FILE}" up --remove-orphans
