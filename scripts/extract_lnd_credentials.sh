#!/bin/bash

# Script to extract LND credentials from Polar and generate environment variables
# Usage: ./extract_lnd_credentials.sh <network_name> <node_name>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLAR_DIR="$HOME/.polar/networks"

# Default values
NETWORK_NAME="Lightning-Test-Network"
NODE_NAME="lnd_alice"

# Override with arguments if provided
if [ $# -ge 1 ]; then
  NETWORK_NAME="$1"
fi

if [ $# -ge 2 ]; then
  NODE_NAME="$2"
fi

# Build paths
NETWORK_PATH="$POLAR_DIR/$NETWORK_NAME"
NODE_PATH="$NETWORK_PATH/nodes/$NODE_NAME"
CERT_FILE="$NODE_PATH/tls.cert"
MACAROON_FILE="$NODE_PATH/admin.macaroon"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     LND Credentials Extractor (Polar to Base64)            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Validation
if [ ! -d "$NETWORK_PATH" ]; then
  echo "❌ Error: Network '$NETWORK_NAME' not found in Polar."
  echo "   Available networks:"
  ls -d $POLAR_DIR/*/ 2>/dev/null | xargs -I {} basename {} || echo "   (none found)"
  exit 1
fi

if [ ! -d "$NODE_PATH" ]; then
  echo "❌ Error: Node '$NODE_NAME' not found in network '$NETWORK_NAME'."
  echo "   Available nodes:"
  ls -d $NETWORK_PATH/nodes/*/ 2>/dev/null | xargs -I {} basename {} || echo "   (none found)"
  exit 1
fi

if [ ! -f "$CERT_FILE" ]; then
  echo "❌ Error: TLS certificate not found at $CERT_FILE"
  exit 1
fi

if [ ! -f "$MACAROON_FILE" ]; then
  echo "❌ Error: Admin macaroon not found at $MACAROON_FILE"
  exit 1
fi

# Extract credentials
echo "📍 Network: $NETWORK_NAME"
echo "📍 Node: $NODE_NAME"
echo ""

echo "🔐 Encoding credentials to Base64..."
CERT_BASE64=$(cat "$CERT_FILE" | base64 -w 0)
MACAROON_BASE64=$(cat "$MACAROON_FILE" | base64 -w 0)

# Find gRPC port from node configuration
GRPC_PORT=10009  # Default
if [ -f "$NODE_PATH/configure.json" ]; then
  GRPC_PORT=$(jq -r '.ports.grpc' "$NODE_PATH/configure.json" 2>/dev/null || echo "10009")
fi

echo ""
echo "✅ Credentials extracted!"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📋 COPY-PASTE into .env file of backend Lightning:"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "LND_GRPC_HOST=127.0.0.1:$GRPC_PORT"
echo ""
echo "LND_MACAROON_BASE64=$MACAROON_BASE64"
echo ""
echo "LND_TLS_CERT_BASE64=$CERT_BASE64"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "💡 Quick setup:"
echo "   1. cd ~/apiLigthning/connect-lnd"
echo "   2. Create/edit .env with the values above"
echo "   3. npm install && npm start"
echo ""
