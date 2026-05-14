#!/bin/bash
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]:-$0}")"
source "${SCRIPT_DIR}/common.sh"

# Fallback wrapper if thunder_api_call was renamed to api_call in newer Thunder versions (like v0.37.0)
if ! command -v thunder_api_call &> /dev/null; then
    thunder_api_call() {
        if command -v api_call &> /dev/null; then
            api_call "$@"
        else
            local method="$1"
            local endpoint="$2"
            local data="${3:-}"
            local url="${THUNDER_API_BASE}${endpoint}"
            if [ -z "$data" ]; then
                curl -k -s -w "\n%{http_code}" -X "$method" "$url" -H "Content-Type: application/json" 2>/dev/null || echo "000"
            else
                curl -k -s -w "\n%{http_code}" -X "$method" "$url" -H "Content-Type: application/json" -d "$data" 2>/dev/null || echo "000"
            fi
        fi
    }
fi
log_info "Creating CFP Tracker application..."

# Fetch DEFAULT_OU_ID
RESPONSE=$(thunder_api_call GET "/organization-units/tree/default")
HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"

if [[ "$HTTP_CODE" == "200" ]]; then
    DEFAULT_OU_ID=$(echo "$BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
else
    log_error "Failed to fetch organization unit by handle 'default'"
    exit 1
fi

# Fetch flow IDs
RESPONSE=$(thunder_api_call GET "/flows?flowType=AUTHENTICATION&limit=10")
HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"
if [[ "$HTTP_CODE" == "200" ]]; then
    AUTH_FLOW_ID=$(echo "$BODY" | grep -o '{[^}]*"id":"[^"]*"[^}]*"handle":"default-basic-flow"[^}]*}' | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

RESPONSE=$(thunder_api_call GET "/flows?flowType=REGISTRATION&limit=10")
HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"
if [[ "$HTTP_CODE" == "200" ]]; then
    REG_FLOW_ID=$(echo "$BODY" | grep -o '{[^}]*"id":"[^"]*"[^}]*"handle":"default-basic-flow"[^}]*}' | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Fallback to the console ones if default doesn't exist
if [[ -z "$AUTH_FLOW_ID" ]]; then
    AUTH_FLOW_ID=$(thunder_api_call GET "/flows?flowType=AUTHENTICATION&limit=100" | grep -o '{[^}]*"id":"[^"]*"[^}]*"handle":"console-authentication-flow"[^}]*}' | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi
if [[ -z "$REG_FLOW_ID" ]]; then
    REG_FLOW_ID=$(thunder_api_call GET "/flows?flowType=REGISTRATION&limit=100" | grep -o '{[^}]*"id":"[^"]*"[^}]*"handle":"console-registration-flow"[^}]*}' | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

RESPONSE=$(thunder_api_call POST "/applications" "{
  \"name\": \"CFP Tracker\",
  \"description\": \"CFP Tracker Next.js Application\",
  \"ouId\": \"${DEFAULT_OU_ID}\",
  \"url\": \"http://localhost:3000\",
  \"logoUrl\": \"emoji:🖲️\",
  \"template\": \"backend\",
  \"authFlowId\": \"${AUTH_FLOW_ID}\",
  \"registrationFlowId\": \"${REG_FLOW_ID}\",
  \"isRegistrationFlowEnabled\": true,
  \"allowedUserTypes\": [\"Person\"],
  \"user_attributes\": [\"given_name\",\"family_name\",\"email\",\"groups\", \"name\", \"ouId\"],
  \"assertion\": {
      \"validityPeriod\": 3600
  },
  \"loginConsent\": {
      \"validityPeriod\": 0
  },
  \"inboundAuthConfig\": [{
    \"type\": \"oauth2\",
    \"config\": {
        \"clientId\": \"cfp-tracker-client\",
        \"clientSecret\": \"cfp-tracker-secret\",
        \"redirectUris\": [\"http://localhost:3000/api/auth/callback\"],
        \"grantTypes\": [\"client_credentials\", \"authorization_code\"],
        \"responseTypes\": [\"code\"],
        \"pkceRequired\": false,
        \"tokenEndpointAuthMethod\": \"client_secret_basic\",
        \"publicClient\": false,
        \"requirePushedAuthorizationRequests\": false,
        \"token\": {
            \"accessToken\": {
                \"validityPeriod\": 3600
            },
            \"idToken\": {
                \"validityPeriod\": 3600,
                \"responseType\": \"JWT\"
            }
        },
        \"scopes\": [\"openid\", \"profile\", \"email\"],
        \"userInfo\": {
            \"responseType\": \"JSON\"
        }
    }
  }]
}")

HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"

if [[ "$HTTP_CODE" == "201" ]] || [[ "$HTTP_CODE" == "200" ]]; then
    log_success "CFP Tracker application created successfully!"
elif [[ "$HTTP_CODE" == "409" ]] || [[ "$BODY" =~ "APP-1022" ]]; then
    log_warning "CFP Tracker application already exists, skipping."
else
    log_error "Failed to create CFP Tracker application (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
    exit 1
fi
