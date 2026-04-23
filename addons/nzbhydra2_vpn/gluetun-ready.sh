#!/usr/bin/with-contenv bash
set -euo pipefail

grep -q '^ *wg0:' /proc/net/dev