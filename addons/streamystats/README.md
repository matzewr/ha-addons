# StreamyStats Home Assistant Add-on

This add-on integrates StreamyStats into your Home Assistant setup.

## Installation

1. Copy this add-on to your Home Assistant `addons` folder.
2. Configure the `config.json` file with your environment variables.
3. Start the add-on from the Home Assistant Supervisor.

## Configuration

- `POSTGRES_USER`: PostgreSQL username (default: `postgres`)
- `POSTGRES_PASSWORD`: PostgreSQL password (default: `postgres`)
- `POSTGRES_DB`: PostgreSQL database name (default: `streamystats`)
- `SESSION_SECRET`: Session secret for encryption
- `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY`: Encryption key for server actions

## Ports

- `3000/tcp`: Web interface