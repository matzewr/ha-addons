# ha-addons

This is a multi-add-on repository for Home Assistant.

Current add-ons:

- Streamystats (`addons/streamystats`)

## Install

1. Open Home Assistant.
2. Add this repository as a custom add-on repository.
3. Install any add-on from this repository (currently `Streamystats`).
4. Start it and open the web UI on port `3000`.

## Add new add-ons later

Create a new folder under `addons/<addon_slug>/` and include at least:

- `config.yaml`
- `Dockerfile`
- `run.sh`

After pushing to GitHub, Home Assistant will list all valid add-ons from this repository URL.

## Streamystats details

- Streamystats AIO container from the upstream project.
- Persistent PostgreSQL data stored inside the add-on data directory.
- Automatic secret generation on first start.

## Notes

- First startup can take a while while PostgreSQL initializes and migrations run.
- The add-on listens on port `3000`.
- Secrets are stored under the add-on data directory and reused on restart.