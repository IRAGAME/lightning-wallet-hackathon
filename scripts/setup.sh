#!/bin/bash

# Setup Complete Lightning Hackathon Project
# This script installs and configures everything needed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR=$(dirname "$SCRIPT_DIR")

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Lightning Custodial Wallet - Hackathon Setup Script      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
  error "Node.js not found. Please install Node.js 14+"
fi
NODE_VERSION=$(node --version)
success "Node.js: $NODE_VERSION"

# Check npm
if ! command -v npm &> /dev/null; then
  error "npm not found. Please install npm"
fi
success "npm: $(npm --version)"

# Check jq
if ! command -v jq &> /dev/null; then
  warning "jq not found. Some scripts may not work optimally."
  warning "Install with: sudo apt install jq"
fi

echo ""
echo "📁 Project Structure:"
echo "   $PROJECT_DIR"
ls -la "$PROJECT_DIR" | grep "^d" | awk '{print "   " $NF}'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Installing Dependencies..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Install Lightning API dependencies
echo ""
info "Installing Lightning API backend..."
cd "$PROJECT_DIR/backends/lightning-api"
npm install
success "Lightning API dependencies installed"

# Install User Backend dependencies
echo ""
info "Installing User Backend..."
cd "$PROJECT_DIR/backends/user-backend"
npm install
success "User Backend dependencies installed"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  Configuring Environment Variables..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Configure Lightning API
LIGHTNING_ENV="$PROJECT_DIR/backends/lightning-api/.env"
if [ ! -f "$LIGHTNING_ENV" ]; then
  info "Creating Lightning API .env..."
  cat > "$LIGHTNING_ENV" << 'EOF'
# Get these values from: ./scripts/extract_lnd_credentials.sh
LND_GRPC_HOST=127.0.0.1:10009
LND_MACAROON_BASE64=
LND_TLS_CERT_BASE64=
PORT=5003
NODE_ENV=development
EOF
  warning "Lightning API .env created"
  warning "⚠️  You need to fill in LND_MACAROON_BASE64 and LND_TLS_CERT_BASE64"
  warning "   Run: cd $PROJECT_DIR && ./scripts/extract_lnd_credentials.sh"
else
  success "Lightning API .env already exists"
fi

# Configure User Backend
USER_ENV="$PROJECT_DIR/backends/user-backend/.env"
if [ ! -f "$USER_ENV" ]; then
  info "Creating User Backend .env..."
  cat > "$USER_ENV" << 'EOF'
PORT=7000
NODE_ENV=development
DATABASE_URL=postgresql://postgres:postgres@localhost:5433/lightning_wallet
JWT_SECRET=change_me_super_secret_key_for_production
JWT_EXPIRES_IN=7d
LIGHTNING_API_BASE_URL=http://localhost:5003/api
PAYMENT_SYNC_INTERVAL_MS=10000
CORS_ORIGIN=http://localhost:3000,http://localhost:3001
EOF
  success "User Backend .env created"
else
  success "User Backend .env already exists"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "📋 Next Steps:"
echo ""
echo "1️⃣  Extract LND Credentials from Polar:"
echo "   cd $PROJECT_DIR"
echo "   ./scripts/extract_lnd_credentials.sh Lightning-Test-Network lnd_alice"
echo ""
echo "2️⃣  Update Lightning API .env:"
echo "   nano backends/lightning-api/.env"
echo "   (Paste the credentials from step 1)"
echo ""
echo "3️⃣  Start Lightning Backend:"
echo "   cd backends/lightning-api"
echo "   npm start"
echo ""
echo "4️⃣  Start User Backend (separate terminal):"
echo "   cd backends/user-backend"
echo "   npm start"
echo ""
echo "5️⃣  Run Complete Test:"
echo "   cd $PROJECT_DIR"
echo "   ./scripts/test_lightning_complete.sh"
echo ""
echo "📚 Documentation:"
echo "   - guides/README_LIGHTNING_TESTING.md"
echo "   - guides/LIGHTNING_QUICK_CHECKLIST.md"
echo "   - guides/GUIDE_LIGHTNING_TESTING.md"
echo ""

echo "✅ All systems ready for Hackathon! 🚀"
echo ""
