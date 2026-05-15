#!/bin/sh
THUNDER_HOME="/opt/thunder"

# Force Thunder to use the Choreo external URL
export BASE_URL="https://b029b391-50fb-49de-9264-d8924e1b1c39.e1-us-east-azure.choreoapps.dev"
export PUBLIC_URL="${BASE_URL}"
export SERVER_PUBLIC_URL="${BASE_URL}"

# Inject database password from environment variable
if [ -n "$AIVEN_DB_PASSWORD" ]; then
    sed -i "s|DATABASE_PASSWORD_PLACEHOLDER|$AIVEN_DB_PASSWORD|g" "$THUNDER_HOME/repository/conf/deployment.yaml"
fi

echo ">>> Starting Thunder (without consent server)..."
exec "$THUNDER_HOME/start.sh" --without-consent
