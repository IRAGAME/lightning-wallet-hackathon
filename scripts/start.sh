#!/bin/bash

# Start Both Backends for Lightning Hackathon
# Usage: ./start.sh [lightning|user|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR=$(dirname "$SCRIPT_DIR")
BACKENDS_DIR="$PROJECT_DIR/backends"

# Default: start all
TARGET="${1:-all}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Lightning Custodial Wallet - Start Backends             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Function to check if .env exists
check_env() {
  local env_file="$1"
  local backend_name="$2"
  
  if [ ! -f "$env_file" ]; then
    echo "❌ $backend_name .env file not found: $env_file"
    echo "   Run: cd $PROJECT_DIR && ./scripts/setup.sh"
    exit 1
  fi
}

# Start Lightning API
start_lightning() {
  check_env "$BACKENDS_DIR/lightning-api/.env" "Lightning API"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🌩️  Starting Lightning API Backend..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  cd "$BACKENDS_DIR/lightning-api"
  
  info "Port: 5003"
  info "Running: npm start"
  info "Press Ctrl+C to stop"
  echo ""
  
  npm start
}

# Start User Backend
start_user() {
  check_env "$BACKENDS_DIR/user-backend/.env" "User Backend"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "👤 Starting User Backend..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  cd "$BACKENDS_DIR/user-backend"
  
  info "Port: 7000"
  info "Running: npm start"
  info "Press Ctrl+C to stop"
  echo ""
  
  npm start
}

# Show usage
show_usage() {
  echo "Usage: ./start.sh [lightning|user|all]"
  echo ""
  echo "Options:"
  echo "  lightning  - Start Lightning API backend only"
  echo "  user       - Start User backend only"
  echo "  all        - Start both backends (default)"
  echo ""
  echo "Note: When starting 'all', open a new terminal for the second backend"
  echo ""
}

# Main
case "$TARGET" in
  lightning)
    start_lightning
    ;;
  user)
    start_user
    ;;
  all)
    echo "ℹ️  Starting both backends..."
    echo ""
    echo "📌 To run both backends simultaneously:"
    echo "   Terminal 1: cd $PROJECT_DIR && ./scripts/start.sh lightning"
    echo "   Terminal 2: cd $PROJECT_DIR && ./scripts/start.sh user"
    echo ""
    echo "💡 Or follow the manual steps in guides/"
    echo ""
    ;;
  *)
    show_usage
    exit 1
    ;;
esac
