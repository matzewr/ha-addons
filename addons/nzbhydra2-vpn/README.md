# Home Assistant Addon: NZBHydra2 mit Gluetun VPN (WireGuard)

Dieses Addon startet NZBHydra2 komplett getunnelt über Gluetun (WireGuard). Die Konfiguration erfolgt entweder über eine WireGuard-Konfigurationsdatei (`.conf`, base64-kodiert) oder über einzelne Variablen im Addon-UI.

## Konfiguration

- **use_conf_file**: Wenn aktiviert, kann eine base64-kodierte WireGuard-Konfigurationsdatei hochgeladen werden (Feld `conf_file`).
- **Alternativ**: Trage die 6 Variablen für WireGuard direkt ein:
  - wg_private_key
  - wg_address
  - wg_dns
  - wg_public_key
  - wg_allowed_ips
  - wg_endpoint

## Ports
- NZBHydra2: 5076 (über VPN getunnelt)

## Hinweise
- Der gesamte Traffic von NZBHydra2 läuft über Gluetun (WireGuard-VPN).
- Die Konfiguration wird beim Start automatisch in die benötigte Form gebracht.
- Die Images werden beim Build aus den offiziellen Quellen geladen.

## Beispiel für WireGuard-Konfigurationsdatei

```
[Interface]
PrivateKey = ...
Address = ...
DNS = ...

[Peer]
PublicKey = ...
AllowedIPs = ...
Endpoint = ...
```

## Support
Dieses Addon ist ein Beispiel und kann nach Bedarf angepasst werden.