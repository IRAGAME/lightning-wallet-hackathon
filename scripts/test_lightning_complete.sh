#!/bin/bash

# Complete Lightning Wallet Testing Script
# This script tests the complete flow:
# 1. Register a user
# 2. Login
# 3. Create a Lightning invoice
# 4. Check payment status
# 5. Get transaction history

set -e

BASE_URL="http://localhost:7000"
LIGHTNING_URL="http://localhost:5003/api"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Lightning Custodial Wallet - Complete Test Suite      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function to print colored messages
success() {
  echo -e "${GREEN}✅ $1${NC}"
}

error() {
  echo -e "${RED}❌ $1${NC}"
  exit 1
}

info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if services are running
check_services() {
  echo ""
  echo "🔍 Checking services..."
  
  # Check User Backend
  if ! curl -s "$BASE_URL/health" > /dev/null; then
    error "User Backend not running on $BASE_URL"
  fi
  success "User Backend: http://localhost:7000"
  
  # Check Lightning Backend
  if ! curl -s "$LIGHTNING_URL/getinfo" > /dev/null 2>&1; then
    warning "Lightning Backend not responding (may impact later tests)"
  else
    success "Lightning Backend: http://localhost:5003/api"
  fi
  
  echo ""
}

# Generate unique username
TIMESTAMP=$(date +%s)
USERNAME="testuser_$TIMESTAMP"
EMAIL="user_$TIMESTAMP@test.local"
PASSWORD="TestPassword123!"

echo "📝 Test Configuration:"
echo "   Username: $USERNAME"
echo "   Email: $EMAIL"
echo "   Base URL: $BASE_URL"
echo ""

# ═══════════════════════════════════════════════════════════════
# 1. REGISTER USER
# ═══════════════════════════════════════════════════════════════

echo "Step 1️⃣  - REGISTRATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"$USERNAME\",
    \"email\": \"$EMAIL\",
    \"phone\": \"+33612345678\",
    \"password\": \"$PASSWORD\"
  }")

if echo "$REGISTER_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "User registered"
  USER_ID=$(echo "$REGISTER_RESPONSE" | jq -r '.data.id')
  echo "   User ID: $USER_ID"
  echo "   Username: $USERNAME"
else
  error "Registration failed: $(echo "$REGISTER_RESPONSE" | jq '.error.message' 2>/dev/null || echo "$REGISTER_RESPONSE")"
fi

# ═══════════════════════════════════════════════════════════════
# 2. LOGIN
# ═══════════════════════════════════════════════════════════════

echo ""
echo "Step 2️⃣  - LOGIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

if echo "$LOGIN_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "User logged in"
  TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.token')
  BALANCE=$(echo "$LOGIN_RESPONSE" | jq -r '.data.user.balance_sats')
  echo "   Token: ${TOKEN:0:20}...${TOKEN: -20}"
  echo "   Initial Balance: $BALANCE sats"
else
  error "Login failed: $(echo "$LOGIN_RESPONSE" | jq '.error.message')"
fi

# ═══════════════════════════════════════════════════════════════
# 3. GET USER INFO
# ═══════════════════════════════════════════════════════════════

echo ""
echo "Step 3️⃣  - GET USER INFO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ME_RESPONSE=$(curl -s -X GET "$BASE_URL/api/me" \
  -H "Authorization: Bearer $TOKEN")

if echo "$ME_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "User info retrieved"
  echo "$ME_RESPONSE" | jq '.data | {id, username, email, balance_sats, status, created_at}'
else
  error "Failed to get user info: $(echo "$ME_RESPONSE" | jq '.error.message')"
fi

# ═══════════════════════════════════════════════════════════════
# 4. CREATE LIGHTNING INVOICE
# ═══════════════════════════════════════════════════════════════

echo ""
echo "Step 4️⃣  - CREATE LIGHTNING INVOICE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

INVOICE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/request-payment" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"amountSats\": 500,
    \"description\": \"Lightning wallet test payment\"
  }")

if echo "$INVOICE_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "Invoice created"
  PAYMENT_ID=$(echo "$INVOICE_RESPONSE" | jq -r '.data.paymentId')
  BOLT11=$(echo "$INVOICE_RESPONSE" | jq -r '.data.bolt11')
  AMOUNT=$(echo "$INVOICE_RESPONSE" | jq -r '.data.amountSats')
  
  echo "   Payment ID: $PAYMENT_ID"
  echo "   Amount: $AMOUNT sats"
  echo "   Status: $(echo "$INVOICE_RESPONSE" | jq -r '.data.status')"
  echo ""
  echo "   📋 Invoice (BOLT11):"
  echo "   $BOLT11"
  echo ""
  echo "   💡 To pay this invoice, use:"
  echo "      lncli -n bob payinvoice $BOLT11"
  
  # Save bolt11 for later reference
  BOLT11_FILE="/tmp/test_invoice_$TIMESTAMP.bolt11"
  echo "$BOLT11" > "$BOLT11_FILE"
  echo "   Saved to: $BOLT11_FILE"
else
  error "Failed to create invoice: $(echo "$INVOICE_RESPONSE" | jq '.error.message')"
fi

# ═══════════════════════════════════════════════════════════════
# 5. CHECK PAYMENT STATUS
# ═══════════════════════════════════════════════════════════════

echo ""
echo "Step 5️⃣  - CHECK PAYMENT STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CHECK_RESPONSE=$(curl -s -X GET "$BASE_URL/api/check-payment/$PAYMENT_ID" \
  -H "Authorization: Bearer $TOKEN")

if echo "$CHECK_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "Payment status retrieved"
  echo "$CHECK_RESPONSE" | jq '.data | {id, amount_sats, status, created_at}'
else
  error "Failed to check payment: $(echo "$CHECK_RESPONSE" | jq '.error.message')"
fi

# ═══════════════════════════════════════════════════════════════
# 6. GET TRANSACTION HISTORY
# ═══════════════════════════════════════════════════════════════

echo ""
echo "Step 6️⃣  - GET TRANSACTION HISTORY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

HISTORY_RESPONSE=$(curl -s -X GET "$BASE_URL/api/history?limit=10&offset=0" \
  -H "Authorization: Bearer $TOKEN")

if echo "$HISTORY_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  success "Transaction history retrieved"
  TX_COUNT=$(echo "$HISTORY_RESPONSE" | jq '.data | length')
  echo "   Total transactions: $TX_COUNT"
  echo ""
  echo "   Recent transactions:"
  echo "$HISTORY_RESPONSE" | jq '.data[] | {id, type, amount_sats, status, created_at}' | head -20
else
  error "Failed to get history: $(echo "$HISTORY_RESPONSE" | jq '.error.message')"
fi

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    ✅ TEST COMPLETE                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "📊 Test Summary:"
echo "   ✅ User Registration: PASSED"
echo "   ✅ User Login: PASSED"
echo "   ✅ Get User Info: PASSED"
echo "   ✅ Create Invoice: PASSED"
echo "   ✅ Check Payment: PASSED"
echo "   ✅ Get History: PASSED"
echo ""

echo "🚀 Next Steps:"
echo "   1. Pay the invoice using Lightning CLI:"
echo "      lncli -n bob payinvoice $BOLT11"
echo ""
echo "   2. Wait 2-3 seconds for confirmation"
echo ""
echo "   3. Run this test again to see updated balance and history"
echo ""

echo "📝 Test Data:"
echo "   Username: $USERNAME"
echo "   Email: $EMAIL"
echo "   Invoice: $BOLT11_FILE"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo ""
