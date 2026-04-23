# NZBHydra2 + Gluetun Add-on (Scaffold)

Dieses Add-on startet zwei Docker-Container ueber die Docker Engine des Hosts:

- `qmcgaw/gluetun`
- `lscr.io/linuxserver/nzbhydra2`

## Enthaltenes Grundgeruest

- Home Assistant Add-on Metadaten in `config.yaml`
- Build-Definition in `Dockerfile`
- Startskript in `run.sh`, das aus den Add-on Optionen eine `docker-compose.yaml` erzeugt und startet

## Wichtige Hinweise

- Das Add-on nutzt `docker_api: true`, um den Docker Socket des Hosts anzusprechen.
- WireGuard wird ueber eine vorhandene Datei `wg0.conf` genutzt.
- Die Datei muss unter `/addon_config/nzbhydra2_vpn/gluetun/wg0.conf` liegen.
- Der Webzugriff auf NZBHydra2 laeuft ueber den konfigurierten Port (Standard: `5076`).
