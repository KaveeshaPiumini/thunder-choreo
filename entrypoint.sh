#!/bin/sh
THUNDER_HOME="/opt/thunder"
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

# Check if DB is actually initialized (not just if setup was attempted)
DB_READY=false
if sqlite3 "$THUNDER_DB/runtimedb.db" "SELECT 1 FROM INBOUND_CLIENT LIMIT 1;" > /dev/null 2>&1; then
    DB_READY=true
fi

if [ "$DB_READY" = "false" ]; then
    echo ">>> Database not initialized, running setup.sh..."
    cd "$THUNDER_HOME" && ./setup.sh
    echo ">>> setup.sh exited with code $?"
else
    echo ">>> Database already initialized, skipping setup."
fi

echo ">>> Starting Thunder (without consent server)..."
exec "$THUNDER_HOME/start.sh" --without-consent
