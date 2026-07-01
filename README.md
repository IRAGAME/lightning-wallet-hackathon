# Lightning Wallet

[![Node.js CI](https://github.com/IRAGAME/lightning-wallet-hackathon/actions/workflows/node.js.yml/badge.svg)](https://github.com/IRAGAME/lightning-wallet-hackathon/actions/workflows/node.js.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> A custodial Lightning Network wallet built for hackathons, featuring multi-service architecture with LND integration.

This project implements a custodial Bitcoin Lightning wallet with three backend services: a Lightning Network API gateway, a payment processing service, and a user-facing wallet backend.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  User API   │────▶│ Lightning    │────▶│   LND Node  │
│  (REST)     │     │  API Gateway │     │  (gRPC)     │
└──────┬──────┘     └──────────────┘     └─────────────┘
       │
┌──────┴──────┐
│  PostgreSQL │
│  (Wallet)   │
└─────────────┘
```

## Sub-Projects

### [lightning-api](./backends/lightning-api)
REST API wrapping LND (Lightning Network Daemon) via gRPC. Provides endpoints for:
- Node info and wallet balance
- Invoice creation and listing
- BOLT11 payment processing
- Sign/verify messages

### [user-backend](./backends/user-backend)
Main custodial wallet backend with:
- User registration and JWT authentication
- Balance management (send/receive/transfer sats)
- Payment request creation and status polling
- Internal transfers between users
- Background payment sync service
- PostgreSQL with row-level locking for atomicity

### [bob-pay](./backends/bob-pay)
Minimal Express server for second LND node payment confirmation.

## Getting Started

### Prerequisites

- Node.js >= 18
- Docker & Docker Compose
- LND node (or use Polar for local testing)

### Installation

```bash
git clone https://github.com/IRAGAME/lightning-wallet-hackathon.git
cd lightning-wallet-hackathon

# Start PostgreSQL
cd backends/user-backend
docker compose up -d

# Configure environment
cp config/.env.lightning.example config/.env.lightning
cp config/.env.user.example config/.env.user
# Edit with your LND credentials

# Install and start lightning-api
cd ../lightning-api
npm install
node index.js

# Install and start user-backend
cd ../user-backend
npm install
node src/server.js
```

## Testing

A comprehensive testing guide is available at [GUIDE_LIGHTNING_TESTING.md](https://github.com/IRAGAME/lightning-wallet-hackathon/blob/main/backends/user-backend/GUIDELIGHTNING_TESTING.md) covering Polar setup, credential extraction, and API testing.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **API Gateway** | Node.js, Express, ln-service (LND gRPC) |
| **User Backend** | Node.js, Express 5, Zod validation |
| **Database** | PostgreSQL 16 |
| **Lightning** | LND, ln-service |
| **Auth** | bcryptjs + JWT |
| **Validation** | Zod |
| **Infrastructure** | Docker Compose |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT - see [LICENSE](LICENSE) for details.
