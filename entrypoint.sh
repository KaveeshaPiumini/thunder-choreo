#!/bin/sh
# Choreo entrypoint: run setup if databases don't exist, then start Thunder
# Use /tmp for flag since /opt/thunder may be read-only in Choreo

SETUP_DONE_FLAG="/tmp/.thunder_setup_done"

if [ ! -f "$SETUP_DONE_FLAG" ]; then
    echo ">>> Running Thunder setup for the first time..."
    cd /opt/thunder && ./setup.sh
    touch "$SETUP_DONE_FLAG"
    echo ">>> Setup complete."
else
    echo ">>> Setup already done, skipping."
fi

echo ">>> Starting Thunder (without consent server)..."
exec /opt/thunder/start.sh --without-consent
