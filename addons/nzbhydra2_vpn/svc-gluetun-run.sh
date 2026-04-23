#!/usr/bin/with-contenv bash
# shellcheck shell=bash

export VPN_SERVICE_PROVIDER="custom"
export VPN_TYPE="wireguard"
export FIREWALL_INPUT_PORTS="5076"

exec s6-notifyoncheck -d -n 300 -w 1000 -c /bin/sh /usr/local/bin/gluetun-ready.sh /usr/local/bin/gluetun-entrypoint