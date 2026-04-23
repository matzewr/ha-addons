#!/usr/bin/env bash
set -e

CONFIG_PATH="/data/options.json"
GLUETUN_DIR="/gluetun"
NZBHYDRA2_DIR="/nzbhydra2"
WG_CONF="$GLUETUN_DIR/wireguard/wg0.conf"

# Parse config
USE_CONF_FILE=$(jq -r '.use_conf_file' "$CONFIG_PATH")

mkdir -p "$GLUETUN_DIR/wireguard"

if [ "$USE_CONF_FILE" = "true" ]; then
    # If conf_file is provided (base64 encoded)
    CONF_FILE=$(jq -r '.conf_file' "$CONFIG_PATH")
    if [ -n "$CONF_FILE" ] && [ "$CONF_FILE" != "null" ]; then
        echo "$CONF_FILE" | base64 -d > "$WG_CONF"
    else
        echo "No WireGuard conf file provided!" >&2
        exit 1
    fi
else
    # Build wg0.conf from variables
    WG_PRIVATE_KEY=$(jq -r '.wg_private_key' "$CONFIG_PATH")
    WG_ADDRESS=$(jq -r '.wg_address' "$CONFIG_PATH")
    WG_DNS=$(jq -r '.wg_dns' "$CONFIG_PATH")
    WG_PUBLIC_KEY=$(jq -r '.wg_public_key' "$CONFIG_PATH")
    WG_ALLOWED_IPS=$(jq -r '.wg_allowed_ips' "$CONFIG_PATH")
    WG_ENDPOINT=$(jq -r '.wg_endpoint' "$CONFIG_PATH")
    cat > "$WG_CONF" <<EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_ADDRESS
DNS = $WG_DNS

[Peer]
PublicKey = $WG_PUBLIC_KEY
AllowedIPs = $WG_ALLOWED_IPS
Endpoint = $WG_ENDPOINT
EOF
fi

# Start Gluetun (VPN)
$GLUETUN_DIR/gluetun \
    --vpn.service-provider custom \
    --vpn.type wireguard \
    --time.zone Europe/Berlin \
    --healthcheck.server-address 0.0.0.0:9999 \
    --webui.listen 0.0.0.0:8000 \
    --port 5076 &

GLUETUN_PID=$!

# Wait for Gluetun to be ready (healthcheck)
for i in {1..30}; do
    if curl -sf http://localhost:9999/v1/health; then
        break
    fi
    sleep 2
done

# Start NZBHydra2 (in background, network is already tunneled)
$NZBHYDRA2_DIR/start.sh &
NZBHYDRA2_PID=$!

wait $GLUETUN_PID $NZBHYDRA2_PID
