# NZBHydra2 VPN

Home Assistant add-on running NZBHydra2 behind a Gluetun WireGuard VPN tunnel.

Traffic for NZBHydra2 is forced through Gluetun in the same container namespace.

## How WireGuard config is provided

Home Assistant add-on options UI does not support direct file upload fields for add-ons.

This add-on supports two methods, with file method taking priority:

1. Place a WireGuard file at `/config/wireguard/wg0.conf` inside the add-on container.
2. Fill the six WireGuard values in add-on options.

Because this add-on maps `addon_config` to `/config`, the host-side path is typically:

- Local repository: `/addon_configs/local_nzbhydra2_vpn/wireguard/wg0.conf`
- GitHub repository: `/addon_configs/<repo_hash>_nzbhydra2_vpn/wireguard/wg0.conf`

Use this file format:

```ini
[Interface]
PrivateKey = ...
Address = 100.34.146.129/32
DNS = 198.18.0.1,198.18.0.2

[Peer]
PublicKey = ...
AllowedIPs = 0.0.0.0/0
Endpoint = 91.56.244.88:51820
```

## Add-on options

- `PUID`: Linux user id for NZBHydra2 files.
- `PGID`: Linux group id for NZBHydra2 files.
- `TZ`: Timezone, for example `Europe/Berlin`.
- `WG_PRIVATE_KEY`: WireGuard interface private key.
- `WG_ADDRESS`: Interface address, for example `100.34.146.129/32`.
- `WG_DNS`: Comma-separated DNS servers.
- `WG_PUBLIC_KEY`: Peer public key.
- `WG_ALLOWED_IPS`: Usually `0.0.0.0/0`.
- `WG_ENDPOINT`: Peer endpoint in `IP:PORT` format.

## Access

After startup, open NZBHydra2 on port `5076`.