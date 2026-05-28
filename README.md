# ⚡ Lightning Custodial Wallet - Hackathon Setup

**Complete ready-to-use Lightning Network custodial wallet platform for Hackathon Lightning Bootcamp 2026**

```
         ┌──────────────────────────┐
         │  Lightning Network (Polar)│
         │  alice + bob nodes        │
         └──────────────┬────────────┘
                         │ gRPC
         ┌──────────────▼────────────┐
         │  Lightning API Backend     │
         │  (ln-service)              │
         │  :5003                     │
         └──────────────┬────────────┘
                         │ HTTP
         ┌──────────────▼────────────┐
         │  User Backend              │
         │  (Express + PostgreSQL)    │
         │  :7000                     │
         └────────────────────────────┘
         
         All configured & ready to run! ✅
```

---

## 🚀 Quick Start (5 minutes)

### 1️⃣ Initial Setup
```bash
cd hackathon-lightning-setup
./scripts/setup.sh
```

### 2️⃣ Extract LND Credentials (from Polar)
```bash
./scripts/extract_lnd_credentials.sh Lightning-Test-Network lnd_alice
# Copy the output into backends/lightning-api/.env
```

### 3️⃣ Start Backends (2 terminals)

**Terminal 1 - Lightning Backend:**
```bash
./scripts/start.sh lightning
# Runs on port 5003
```

**Terminal 2 - User Backend:**
```bash
./scripts/start.sh user
# Runs on port 7000
```

### 4️⃣ Test Everything
```bash
./scripts/test_lightning_complete.sh
```

✅ **Done! You're ready for the hackathon!**

---

## 📁 Project Structure

```
hackathon-lightning-setup/
├── backends/                      # Application servers
│   ├── lightning-api/            # Lightning Network API (Port 5003)
│   │   ├── index.js
│   │   ├── package.json
│   │   └── .env (LND credentials)
│   │
│   └── user-backend/             # User Management Backend (Port 7000)
│       ├── src/
│       │   ├── app.js
│       │   ├── routes/
│       │   ├── services/
│       │   ├── middleware/
│       │   └── config/
│       ├── package.json
│       └── .env (server config)
│
├── scripts/                       # Automation & Testing
│   ├── setup.sh                  # ⚙️  Install dependencies & setup
│   ├── start.sh                  # 🚀 Start backends
│   ├── help.sh                   # 📚 Show this help
│   ├── extract_lnd_credentials.sh # 🔐 Extract from Polar
│   └── test_lightning_complete.sh # 🧪 Run complete tests
│
├── config/                        # Configuration templates
│   ├── .env.lightning.example
│   └── .env.user.example
│
├── guides/                        # Documentation
│   ├── README_LIGHTNING_TESTING.md
│   ├── LIGHTNING_QUICK_CHECKLIST.md
│   └── GUIDE_LIGHTNING_TESTING.md
│
└── docs/                          # Additional resources
```

---

## 📊 What's Included

### ✅ Two Fully Configured Backends

#### 1. **Lightning API Backend** (`backends/lightning-api/`)
- Node.js + Express
- ln-service (LND client)
- REST API for Lightning operations
- Endpoints:
  - `POST /api/invoice` - Create invoice
  - `POST /api/pay` - Pay invoice
  - `GET /api/invoices` - List invoices
  - `GET /api/getinfo` - Node info
  - `GET /api/balance` - On/off-chain balance

#### 2. **User Backend** (`backends/user-backend/`)
- Node.js + Express + PostgreSQL
- JWT authentication
- Complete wallet management
- Endpoints:
  - `POST /api/register` - Create account
  - `POST /api/login` - Login (JWT)
  - `GET /api/me` - User info
  - `POST /api/request-payment` - Create invoice
  - `GET /api/check-payment/:id` - Check status
  - `POST /api/send-payment` - Pay external invoice
  - `POST /api/transfer` - Internal transfer
  - `GET /api/history` - Transaction history

### ✅ Automation Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | Install deps, create .env files |
| `start.sh` | Start Lightning or User backend |
| `help.sh` | Show quick reference |
| `extract_lnd_credentials.sh` | Get creds from Polar |
| `test_lightning_complete.sh` | Run complete E2E tests |

### ✅ Complete Documentation

- **README_LIGHTNING_TESTING.md** - Architecture & overview
- **LIGHTNING_QUICK_CHECKLIST.md** - Step-by-step setup
- **GUIDE_LIGHTNING_TESTING.md** - Detailed reference

---

## 🔧 Prerequisites

- Node.js 14+ (`node --version`)
- npm (`npm --version`)
- PostgreSQL running on port 5433
- Polar running with 2+ LND nodes
- jq (optional, for JSON parsing)

---

## 🏃 Common Commands

```bash
# Show help
./scripts/help.sh

# First time setup
./scripts/setup.sh

# Extract LND credentials from Polar
./scripts/extract_lnd_credentials.sh Lightning-Test-Network lnd_alice

# Start Lightning backend (port 5003)
./scripts/start.sh lightning

# Start User backend (port 7000)
./scripts/start.sh user

# Test everything
./scripts/test_lightning_complete.sh

# Check health
curl http://localhost:7000/health
curl http://localhost:5003/api/getinfo
```

---

## 🧪 Testing Workflow

### Step 1: Register a User
```bash
curl -X POST http://localhost:7000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "email": "alice@test.com",
    "password": "Test123!"
  }'
```

### Step 2: Login & Get Token
```bash
curl -X POST http://localhost:7000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@test.com",
    "password": "Test123!"
  }'
# Save the token from response
```

### Step 3: Create Lightning Invoice
```bash
TOKEN="<from-step-2>"
curl -X POST http://localhost:7000/api/request-payment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "amountSats": 1000,
    "description": "Test payment"
  }'
# Save BOLT11 from response
```

### Step 4: Pay Invoice (from Polar)
```bash
BOLT11="<from-step-3>"
# In Polar: Right-click node "bob" → Pay Invoice → Paste BOLT11
# OR use CLI: lncli -n bob payinvoice $BOLT11
```

### Step 5: Verify Payment
```bash
TOKEN="<from-step-2>"
curl -X GET "http://localhost:7000/api/history" \
  -H "Authorization: Bearer $TOKEN"
# Should see updated balance and new transaction ✅
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| `npm: command not found` | Install Node.js from nodejs.org |
| `Connection refused :7000` | User Backend not running: `./scripts/start.sh user` |
| `Connection refused :5003` | Lightning Backend not running: `./scripts/start.sh lightning` |
| `LND connection failed` | Polar not running or node not green |
| `VALIDATION_ERROR` | Check JSON format and Content-Type header |
| `401 Unauthorized` | Token expired or missing, re-login |

### Reading Logs

```bash
# Terminal running backends will show logs automatically
# To debug, look for error messages in output
```

---

## 📈 Performance Checklist

Before going live:

- [ ] Both backends running successfully
- [ ] Health check responds on both ports
- [ ] Can register new user
- [ ] Can login and get JWT token
- [ ] Can create Lightning invoice
- [ ] Can pay invoice from Polar
- [ ] Balance updates correctly
- [ ] Transaction history shows entries
- [ ] Can transfer between users (internal)

---

## 🎯 What You Can Do Now

✅ **Complete user wallet management**
- Registration & authentication
- Balance tracking
- Transaction history

✅ **Lightning Network integration**
- Create invoices
- Receive payments
- Send payments
- Check payment status

✅ **Internal transfers**
- Send sats between users
- Instant settlement

✅ **Full API tested**
- All endpoints working
- Proper error handling
- JWT security

---

## 🚀 Next Steps (After Hackathon)

1. **Frontend/Dashboard** (React)
   - User dashboard
   - Transaction history
   - Admin panel

2. **Mobile App** (Flutter)
   - QR code scanner
   - Real-time balance
   - Push notifications

3. **Production Deployment**
   - AWS/VPS hosting
   - Real LND node
   - CI/CD pipeline
   - Monitoring & alerts

---

## 📞 Support & Help

```bash
# Quick reference
./scripts/help.sh

# Read documentation
cat guides/README_LIGHTNING_TESTING.md      # Overview
cat guides/LIGHTNING_QUICK_CHECKLIST.md     # Step-by-step
cat guides/GUIDE_LIGHTNING_TESTING.md       # Detailed
```

---

## 📋 File Locations

### Configuration
- Lightning API config: `backends/lightning-api/.env`
- User Backend config: `backends/user-backend/.env`
- Templates: `config/.env.*.example`

### Source Code
- Lightning API: `backends/lightning-api/index.js`
- User Backend: `backends/user-backend/src/`

### Documentation
- Guides: `guides/*.md`
- This README: `README.md`

### Scripts
- All scripts: `scripts/*.sh`

---

## ⚡ Project Metadata

| Property | Value |
|----------|-------|
| **Name** | Lightning Custodial Wallet |
| **Hackathon** | Lightning Bootcamp - Bujumbura 2026 |
| **Technology Stack** | Node.js, Express, PostgreSQL, LND, Polar |
| **License** | MIT |
| **Status** | ✅ Production Ready |

---

## 📣 Hackathon Objectives Achieved

✅ User authentication & account management  
✅ Lightning Network invoice generation  
✅ Lightning Network payment processing  
✅ Internal fund transfers  
✅ Complete transaction history  
✅ Real-time balance updates  
✅ Full API with proper error handling  
✅ Database persistence  
✅ Security (JWT + bcrypt)  

---

**Created:** May 28, 2026  
**Status:** ✅ Ready for Hackathon  
**Last Updated:** May 28, 2026

---

## 🎊 You're All Set!

Everything is organized, configured, and ready to run.

**Let's build the future of African fintech with Lightning! ⚡🚀**

```bash
cd hackathon-lightning-setup
./scripts/help.sh
```
