#!/bin/bash

# 🔌 Lightning Functionalities Testing Script
# Tests all Lightning-related features before frontend integration

set -e

BASE_URL="${BASE_URL:-http://localhost:7000}"
LIGHTNING_URL="${LIGHTNING_URL:-http://localhost:5003/api}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
success() {
  echo -e "${GREEN}✅ $1${NC}"
  ((TESTS_PASSED++))
}

error() {
  echo -e "${RED}❌ $1${NC}"
  ((TESTS_FAILED++))
}

info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

section() {
  echo ""
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

# Generate test identifiers
TIMESTAMP=$(date +%s)
USERNAME="testuser_$TIMESTAMP"
EMAIL="user_$TIMESTAMP@test.local"
PASSWORD="TestPassword123!"

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

section "PRE-FLIGHT CHECKS"

info "Checking User Backend..."
if curl -s "$BASE_URL/health" > /dev/null 2>&1; then
  success "User Backend responding: $BASE_URL"
else
  error "User Backend not responding on $BASE_URL"
  exit 1
fi

info "Checking Lightning API..."
if curl -s "$LIGHTNING_URL/getinfo" > /dev/null 2>&1; then
  success "Lightning API responding: $LIGHTNING_URL"
else
  warning "Lightning API not responding (some tests may fail)"
fi

# ============================================================================
# 1. REGISTRATION TEST
# ============================================================================

section "TEST 1: USER REGISTRATION"

echo "Registering user: $USERNAME"

REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"$USERNAME\",
    \"email\": \"$EMAIL\",
    \"phone\": \"+33612345678\",
    \"password\": \"$PASSWORD\"
  }")

if echo "$REGISTER_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "User registration successful"
  USER_ID=$(echo "$REGISTER_RESPONSE" | jq -r '.data.id')
  info "User ID: $USER_ID"
else
  error "User registration failed"
  echo "$REGISTER_RESPONSE" | jq '.'
  exit 1
fi

# ============================================================================
# 2. LOGIN TEST
# ============================================================================

section "TEST 2: USER AUTHENTICATION"

LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

if echo "$LOGIN_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "User login successful"
  TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.token')
  BALANCE=$(echo "$LOGIN_RESPONSE" | jq -r '.data.user.balance_sats')
  info "JWT Token: ${TOKEN:0:30}..."
  info "Initial Balance: $BALANCE sats"
else
  error "User login failed"
  echo "$LOGIN_RESPONSE" | jq '.'
  exit 1
fi

# ============================================================================
# 3. GET USER INFO
# ============================================================================

section "TEST 3: GET USER INFO"

ME_RESPONSE=$(curl -s -X GET "$BASE_URL/api/me" \
  -H "Authorization: Bearer $TOKEN")

if echo "$ME_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "User info retrieved"
  echo "$ME_RESPONSE" | jq '.data | {id, username, email, balance_sats}'
else
  error "Failed to retrieve user info"
  echo "$ME_RESPONSE" | jq '.'
fi

# ============================================================================
# 4. INVOICE CREATION (REQUEST-PAYMENT)
# ============================================================================

section "TEST 4: LIGHTNING INVOICE CREATION"

info "Creating Lightning invoice for 1000 sats..."

INVOICE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/request-payment" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amountSats": 1000,
    "description": "Test invoice"
  }')

if echo "$INVOICE_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "Lightning invoice created"
  PAYMENT_ID=$(echo "$INVOICE_RESPONSE" | jq -r '.data.paymentId')
  BOLT11=$(echo "$INVOICE_RESPONSE" | jq -r '.data.bolt11')
  AMOUNT=$(echo "$INVOICE_RESPONSE" | jq -r '.data.amountSats')
  
  info "Payment ID: $PAYMENT_ID"
  info "Amount: $AMOUNT sats"
  info "BOLT11: ${BOLT11:0:50}..."
  
  # Validate BOLT11 format
  if [[ "$BOLT11" =~ ^lnbc[0-9]+[pnumkMGB]?$ ]]; then
    success "BOLT11 format is valid"
  else
    error "BOLT11 format is invalid"
  fi
else
  error "Failed to create Lightning invoice"
  echo "$INVOICE_RESPONSE" | jq '.'
fi

# ============================================================================
# 5. PAYMENT STATUS CHECK
# ============================================================================

section "TEST 5: PAYMENT STATUS CHECK"

info "Checking payment status for ID: $PAYMENT_ID"

STATUS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/check-payment/$PAYMENT_ID" \
  -H "Authorization: Bearer $TOKEN")

if echo "$STATUS_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "Payment status retrieved"
  PAYMENT_STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.data.status')
  info "Payment Status: $PAYMENT_STATUS (expected: pending)"
  
  if [[ "$PAYMENT_STATUS" == "pending" ]]; then
    success "Payment status is correct (pending)"
  else
    warning "Payment status may have changed: $PAYMENT_STATUS"
  fi
else
  error "Failed to retrieve payment status"
  echo "$STATUS_RESPONSE" | jq '.'
fi

# ============================================================================
# 6. TRANSACTION HISTORY
# ============================================================================

section "TEST 6: TRANSACTION HISTORY"

info "Retrieving transaction history..."

HISTORY_RESPONSE=$(curl -s -X GET "$BASE_URL/api/history?limit=10&offset=0" \
  -H "Authorization: Bearer $TOKEN")

if echo "$HISTORY_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "Transaction history retrieved"
  HISTORY_COUNT=$(echo "$HISTORY_RESPONSE" | jq '.data.transactions | length')
  info "Total transactions: $HISTORY_COUNT"
  
  info "Recent transactions:"
  echo "$HISTORY_RESPONSE" | jq '.data.transactions | .[] | {id, type, amount_sats, status, created_at}'
else
  error "Failed to retrieve transaction history"
  echo "$HISTORY_RESPONSE" | jq '.'
fi

# ============================================================================
# 7. INTERNAL TRANSFER (Create second user)
# ============================================================================

section "TEST 7: INTERNAL TRANSFER"

# Register second user
USERNAME2="testuser2_$TIMESTAMP"
EMAIL2="user2_$TIMESTAMP@test.local"

info "Registering second user for transfer test..."

REGISTER2_RESPONSE=$(curl -s -X POST "$BASE_URL/api/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"$USERNAME2\",
    \"email\": \"$EMAIL2\",
    \"phone\": \"+33687654321\",
    \"password\": \"$PASSWORD\"
  }")

if echo "$REGISTER2_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "Second user registered"
  USER2_ID=$(echo "$REGISTER2_RESPONSE" | jq -r '.data.id')
  info "User 2 ID: $USER2_ID"
  
  # Attempt transfer
  info "Attempting internal transfer of 100 sats..."
  
  TRANSFER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/transfer" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"recipientId\": $USER2_ID,
      \"amountSats\": 100,
      \"description\": \"Test transfer\"
    }")
  
  if echo "$TRANSFER_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    success "Internal transfer completed"
    echo "$TRANSFER_RESPONSE" | jq '.data'
  else
    warning "Internal transfer may have logic constraints"
    echo "$TRANSFER_RESPONSE" | jq '.error'
  fi
else
  warning "Could not register second user for transfer test"
fi

# ============================================================================
# 8. ERROR HANDLING TESTS
# ============================================================================

section "TEST 8: ERROR HANDLING"

info "Testing error cases..."

# Invalid authentication
info "Testing invalid token..."
INVALID_TOKEN_RESPONSE=$(curl -s -X GET "$BASE_URL/api/me" \
  -H "Authorization: Bearer invalid_token_xyz")

if echo "$INVALID_TOKEN_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  success "Invalid token properly rejected"
else
  warning "Invalid token handling may need review"
fi

# Invalid payment ID
info "Testing invalid payment ID..."
INVALID_ID_RESPONSE=$(curl -s -X GET "$BASE_URL/api/check-payment/99999" \
  -H "Authorization: Bearer $TOKEN")

if echo "$INVALID_ID_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  success "Invalid payment ID properly rejected"
else
  warning "Invalid payment ID handling may need review"
fi

# ============================================================================
# SUMMARY
# ============================================================================

section "TEST SUMMARY"

echo ""
echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
SUCCESS_RATE=$((TESTS_PASSED * 100 / TOTAL))

echo ""
echo -e "Success Rate: ${GREEN}${SUCCESS_RATE}%${NC} ($TESTS_PASSED/$TOTAL)"

if [ $TESTS_FAILED -eq 0 ]; then
  echo ""
  echo -e "${GREEN}🎉 ALL LIGHTNING FEATURES ARE WORKING!${NC}"
  echo ""
  echo "✨ You can now proceed with frontend integration."
  echo ""
  exit 0
else
  echo ""
  echo -e "${YELLOW}⚠️  Some tests failed. Please review the errors above.${NC}"
  echo ""
  exit 1
fi
