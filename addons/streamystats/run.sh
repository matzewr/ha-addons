#!/bin/bash

# Symlink für persistente PostgreSQL-Daten
if [ ! -d /var/lib/postgresql/data ]; then
	rm -rf /var/lib/postgresql/data
	ln -s /data /var/lib/postgresql/data
fi

# Start the StreamyStats service
exec node /app