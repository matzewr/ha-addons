#!/usr/bin/with-contenv bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"
WG_TARGET_FILE="/gluetun/wireguard/wg0.conf"
WG_USER_FILE="/config/wireguard/wg0.conf"

read_option() {
    local key="$1"
    local default="$2"

    if [ ! -f "${OPTIONS_FILE}" ]; then
        printf '%s' "${default}"
        return
    fi

    local value
    value="$(sed -n -E 's/.*"'"${key}"'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' "${OPTIONS_FILE}" | head -n1)"
    if [ -n "${value}" ]; then
        printf '%s' "${value}"
        return
    fi

    value="$(sed -n -E 's/.*"'"${key}"'"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "${OPTIONS_FILE}" | head -n1)"
    if [ -n "${value}" ]; then
        printf '%s' "${value}"
        return
    fi

    printf '%s' "${default}"
}

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
        echo "[error] Provide /config/wireguard/wg0.conf or set the WireGuard add-on options"
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