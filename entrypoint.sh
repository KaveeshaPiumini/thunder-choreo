#!/bin/sh
THUNDER_HOME="/opt/thunderid"
THUNDER_DB="/tmp/thunder-db"
THUNDER_SECURITY="/tmp/thunder-security"

echo ">>> Setting up writable directories in /tmp..."
mkdir -p "$THUNDER_DB"
mkdir -p "$THUNDER_SECURITY"

# Copy security keys to writable /tmp
if [ -d "$THUNDER_HOME/repository/resources/security" ]; then
    cp -n "$THUNDER_HOME/repository/resources/security/"* "$THUNDER_SECURITY/" 2>/dev/null || true
    echo ">>> Security files copied to $THUNDER_SECURITY"
fi

# Initialize SQLite schemas if the files don't exist
if [ ! -f "$THUNDER_DB/configdb.db" ]; then
    echo ">>> Initializing configdb.db schema..."
    sqlite3 "$THUNDER_DB/configdb.db" < "$THUNDER_HOME/dbscripts/configdb/sqlite.sql"
fi

if [ ! -f "$THUNDER_DB/runtimedb.db" ]; then
    echo ">>> Initializing runtimedb.db schema..."
    sqlite3 "$THUNDER_DB/runtimedb.db" < "$THUNDER_HOME/dbscripts/runtimedb/sqlite.sql"
fi

if [ ! -f "$THUNDER_DB/userdb.db" ]; then
    echo ">>> Initializing userdb.db schema..."
    sqlite3 "$THUNDER_DB/userdb.db" < "$THUNDER_HOME/dbscripts/userdb/sqlite.sql"
fi

# Check if bootstrap data is already inserted
DB_READY=false
if sqlite3 "$THUNDER_DB/runtimedb.db" "SELECT 1 FROM INBOUND_CLIENT LIMIT 1;" > /dev/null 2>&1; then
    DB_READY=true
fi

if [ "$DB_READY" = "false" ]; then
    echo ">>> Database schema is present but no data found, running setup.sh to bootstrap..."
    cd "$THUNDER_HOME" && ./setup.sh
    echo ">>> setup.sh exited with code $?"
else
    echo ">>> Database already bootstrapped, skipping setup.sh."
fi

# Export environment variable to skip security
export SKIP_SECURITY=true

echo ">>> Starting Thunder (without consent server)..."
exec "$THUNDER_HOME/start.sh" --without-consent
