#!/bin/sh
THUNDER_HOME="/opt/thunderid"

# Force Thunder to use the Choreo external URL
export BASE_URL="https://b029b391-50fb-49de-9264-d8924e1b1c39.e1-us-east-azure.choreoapps.dev"
export PUBLIC_URL="${BASE_URL}"
export SERVER_PUBLIC_URL="${BASE_URL}"
export LOG_LEVEL=DEBUG

echo ">>> Starting Thunder (without consent server)..."
exec "$THUNDER_HOME/start.sh" --without-consent
