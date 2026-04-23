#!/usr/bin/with-contenv bash
# shellcheck shell=bash

export VPN_SERVICE_PROVIDER="custom"
export VPN_TYPE="wireguard"
export FIREWALL_INPUT_PORTS="5076"

exec s6-notifyoncheck -d -n 300 -w 1000 -c "grep -q '^ *wg0:' /proc/net/dev" /usr/local/bin/gluetun-entrypoint