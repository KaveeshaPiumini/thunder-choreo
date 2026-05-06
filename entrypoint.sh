#!/bin/sh
# Choreo entrypoint: run setup if databases don't exist, then start Thunder

SETUP_DONE_FLAG="/opt/thunder/repository/database/.setup_done"

if [ ! -f "$SETUP_DONE_FLAG" ]; then
    echo ">>> Running Thunder setup for the first time..."
    cd /opt/thunder && ./setup.sh
    touch "$SETUP_DONE_FLAG"
    echo ">>> Setup complete."
else
    echo ">>> Setup already done, skipping."
fi

echo ">>> Starting Thunder..."
exec /opt/thunder/start.sh --without-consent
