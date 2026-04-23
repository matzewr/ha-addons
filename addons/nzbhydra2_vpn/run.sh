#!/usr/bin/with-contenv bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"
WG_TARGET_FILE="/gluetun/wireguard/wg0.conf"
WG_USER_FILE="/config/wireguard/wg0.conf"

read_option() {
    local key="$1"
    local default="$2"

    if [ -f "${OPTIONS_FILE}" ]; then
        jq -r --arg key "${key}" --arg def "${default}" '.[$key] // $def' "${OPTIONS_FILE}"
    else
        printf '%s' "${default}"
    fi
}

PUID="$(read_option "PUID" "1000")"
PGID="$(read_option "PGID" "1000")"
TZ="$(read_option "TZ" "Europe/Berlin")"

WG_PRIVATE_KEY="$(read_option "WG_PRIVATE_KEY" "")"
WG_ADDRESS="$(read_option "WG_ADDRESS" "")"
WG_DNS="$(read_option "WG_DNS" "198.18.0.1,198.18.0.2")"
WG_PUBLIC_KEY="$(read_option "WG_PUBLIC_KEY" "")"
WG_ALLOWED_IPS="$(read_option "WG_ALLOWED_IPS" "0.0.0.0/0")"
WG_ENDPOINT="$(read_option "WG_ENDPOINT" "")"

mkdir -p /gluetun/wireguard /config/wireguard

if [ -s "${WG_USER_FILE}" ]; then
    echo "[info] Using WireGuard file from ${WG_USER_FILE}"
    cp "${WG_USER_FILE}" "${WG_TARGET_FILE}"
else
    missing=0
    for value_name in WG_PRIVATE_KEY WG_ADDRESS WG_PUBLIC_KEY WG_ALLOWED_IPS WG_ENDPOINT; do
        if [ -z "${!value_name}" ]; then
            echo "[error] Missing required option: ${value_name}"
            missing=1
        fi
    done
    if [ "${missing}" -ne 0 ]; then
        echo "[error] Provide /config/wireguard/wg0.conf or set the required WireGuard options in add-on configuration"
        exit 1
    fi

    cat > "${WG_TARGET_FILE}" <<EOF
[Interface]
PrivateKey = ${WG_PRIVATE_KEY}
Address = ${WG_ADDRESS}
DNS = ${WG_DNS}

[Peer]
PublicKey = ${WG_PUBLIC_KEY}
AllowedIPs = ${WG_ALLOWED_IPS}
Endpoint = ${WG_ENDPOINT}
EOF
fi

chmod 600 "${WG_TARGET_FILE}"

export PUID
export PGID
export TZ

export VPN_SERVICE_PROVIDER="custom"
export VPN_TYPE="wireguard"
export FIREWALL_INPUT_PORTS="5076"

echo "[info] Starting Gluetun"
/usr/local/bin/gluetun-entrypoint &
GLUETUN_PID=$!

for _ in $(seq 1 90); do
    if ! kill -0 "${GLUETUN_PID}" 2>/dev/null; then
        echo "[error] Gluetun exited unexpectedly"
        wait "${GLUETUN_PID}" || true
        exit 1
    fi
    if ip link show wg0 >/dev/null 2>&1; then
        echo "[info] WireGuard interface wg0 is up"
        break
    fi
    sleep 1
done

if ! ip link show wg0 >/dev/null 2>&1; then
    echo "[error] WireGuard interface wg0 did not come up in time"
    exit 1
fi

echo "[info] Starting NZBHydra2"
exec /init