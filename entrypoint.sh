#!/bin/sh
# Choreo entrypoint for Thunder
# Choreo runs containers with a read-only root filesystem.
# All writable data (databases, security keys) must live in /tmp.

THUNDER_HOME="/opt/thunder"
THUNDER_DB="/tmp/thunder-db"
THUNDER_SECURITY="/tmp/thunder-security"
SETUP_FLAG="/tmp/.thunder_setup_v6"

echo ">>> Setting up writable directories in /tmp..."
mkdir -p "$THUNDER_DB"
mkdir -p "$THUNDER_SECURITY"

# Copy security keys from read-only image to writable /tmp
# (signing keys and crypto key are baked into the image by the build)
if [ -d "$THUNDER_HOME/repository/resources/security" ]; then
    cp -n "$THUNDER_HOME/repository/resources/security/"* "$THUNDER_SECURITY/" 2>/dev/null || true
    echo ">>> Security files copied to $THUNDER_SECURITY"
fi

# Run setup only if not already done
if [ ! -f "$SETUP_FLAG" ]; then
    echo ">>> Running Thunder setup for the first time..."
    cd "$THUNDER_HOME" && ./setup.sh
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        touch "$SETUP_FLAG"
        echo ">>> Setup complete successfully."
    else
        echo ">>> WARNING: setup.sh exited with code $EXIT_CODE — continuing anyway..."
        touch "$SETUP_FLAG"
    fi
else
    echo ">>> Setup already done, skipping."
fi

echo ">>> Starting Thunder (without consent server)..."
exec "$THUNDER_HOME/start.sh" --without-consent
