#!/bin/bash
source "${SCRIPT_DIR}/common.sh"

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
    AUTH_FLOW_ID=$(echo "$BODY" | grep -o '{[^}]*"id":"[^"]*"[^}]*"handle":"default-authentication-flow"[^}]*}' | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

RESPONSE=$(thunder_api_call GET "/flows?flowType=REGISTRATION&limit=10")
HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"
if [[ "$HTTP_CODE" == "200" ]]; then
    REG_FLOW_ID=$(echo "$BODY" | grep -o '{[^}]*"id":"[^"]*"[^}]*"handle":"default-registration-flow"[^}]*}' | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
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
  \"logoUrl\": \"emoji:🎤\",
  \"authFlowId\": \"${AUTH_FLOW_ID}\",
  \"registrationFlowId\": \"${REG_FLOW_ID}\",
  \"isRegistrationFlowEnabled\": false,
  \"allowedUserTypes\": [\"Person\"],
  \"user_attributes\": [\"given_name\",\"family_name\",\"email\",\"groups\", \"name\", \"ouId\"],
  \"inboundAuthConfig\": [{
    \"type\": \"oauth2\",
    \"config\": {
        \"clientId\": \"cfp-tracker-client\",
        \"redirectUris\": [\"http://localhost:3000/api/auth/callback\"],
        \"grantTypes\": [\"authorization_code\", \"refresh_token\"],
        \"responseTypes\": [\"code\"],
        \"pkceRequired\": true,
        \"tokenEndpointAuthMethod\": \"none\",
        \"publicClient\": true,
        \"token\": {
            \"accessToken\": {
                \"validityPeriod\": 3600,
                \"userAttributes\": [\"given_name\",\"family_name\",\"email\",\"groups\", \"name\", \"ouId\"]
            },
            \"idToken\": {
                \"validityPeriod\": 3600,
                \"userAttributes\": [\"given_name\",\"family_name\",\"email\",\"groups\", \"name\", \"ouId\"]
            }
        },
        \"scopeClaims\": {
            \"profile\": [\"name\",\"given_name\",\"family_name\",\"picture\"],
            \"email\": [\"email\",\"email_verified\"],
            \"phone\": [\"phone_number\",\"phone_number_verified\"],
            \"group\": [\"groups\"],
            \"ou\": [\"ouId\"]
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
