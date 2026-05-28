# 🌩️ Guide Complet - Test des Fonctionnalités Lightning

## 📋 Vue d'Ensemble

Ce guide vous permet de tester complètement le système Lightning Custodial Wallet avec:
- ✅ 2-4 nœuds LND configurés dans Polar
- ✅ Backend Lightning (`apiLigthning/connect-lnd`) lancé
- ✅ User Backend testant les créations d'invoices, paiements, transferts
- ✅ Tests des flux complets en temps réel

---

## 🏗️ Architecture de Test

```
┌─────────────────────────────────────────┐
│         Polar (Local Bitcoin)            │
│  NodeA (LND₁) ←→ NodeB (LND₂)           │
│  NodeC (LND₃) ←→ NodeD (LND₄)           │
└─────────────────────────────────────────┘
             ↓ gRPC Port 10009
┌─────────────────────────────────────────┐
│    Backend Lightning (ln-service API)    │
│   http://localhost:5003/api               │
│                                          │
│ POST /invoice  - Créer une facture       │
│ POST /pay      - Payer une facture       │
│ GET  /invoices - Lister les invoices     │
│ GET  /getinfo  - Infos du nœud           │
│ GET  /balance  - Balances (on/off-chain) │
└─────────────────────────────────────────┘
             ↓ HTTP (port 5003)
┌─────────────────────────────────────────┐
│      User Backend (Node.js Express)      │
│   http://localhost:7000/api              │
│                                          │
│ POST /register           - Créer compte  │
│ POST /login              - Connexion     │
│ POST /request-payment    - Invoice       │
│ POST /send-payment       - Paiement      │
│ POST /transfer           - Transfert     │
│ GET  /history            - Historique    │
└─────────────────────────────────────────┘
```

---

## 🚀 Étape 1: Configurer Polar

### 1.1 Ouvrir Polar

```bash
# Si Polar n'est pas encore installé
cd ~/polar-linux-x86_64-v4.0.0.AppImage
chmod +x polar-linux-x86_64-v4.0.0.AppImage
./polar-linux-x86_64-v4.0.0.AppImage &
```

### 1.2 Créer une nouvelle Network

1. **Cliquez sur "Create Network"**
2. **Nommez-la**: `Lightning-Test-Network`
3. **Sélectionnez**:
   - Bitcoin Core version: latest
   - LND: latest

### 1.3 Ajouter 2-4 nœuds LND

1. **Cliquez sur "+"** en bas
2. **Sélectionnez "Add Node"** → **LND**
3. **Créez**:
   - `alice` (LND Node 1)
   - `bob` (LND Node 2)
   - `charlie` (LND Node 3) - optionnel

### 1.4 Lancer la Network

1. **Cliquez sur "Start Network"** (▶️ bouton)
2. ⏳ Attendez que tous les nœuds soient verts (2-3 minutes)
3. ✅ Statut: **All nodes started**

### 1.5 Ouvrir les Ports gRPC

Dans Polar, pour chaque nœud:
1. **Cliquez sur le nœud** (ex: alice)
2. **Tab "Connect"** ou **⚙️ Settings**
3. **Notez les informations**:
   - **gRPC Host**: `127.0.0.1:10009` (ou le port affiché)
   - Vous récupérerez les credentials après

---

## 🔐 Étape 2: Extracting LND Credentials

### 2.1 Accéder aux dossiers LND dans Polar

Les credentials sont stockés dans: `~/.polar/networks/*/nodes/`

```bash
# Exemple pour alice
ls -la ~/.polar/networks/Lightning-Test-Network/nodes/lnd_alice/
```

Vous devriez voir:
```
tls.cert
admin.macaroon
readonly.macaroon
```

### 2.2 Encoder les credentials en Base64

**Créer un script** `extract_credentials.sh`:

```bash
#!/bin/bash

NETWORK_PATH="$HOME/.polar/networks/Lightning-Test-Network"
NODE_NAME="lnd_alice"  # Changez selon le nœud

CERT_PATH="$NETWORK_PATH/nodes/$NODE_NAME/tls.cert"
MACAROON_PATH="$NETWORK_PATH/nodes/$NODE_NAME/admin.macaroon"

echo "=== LND Credentials for $NODE_NAME ==="
echo ""
echo "Certificate (TLS_CERT_BASE64):"
cat "$CERT_PATH" | base64 -w 0
echo ""
echo ""
echo "Macaroon (MACAROON_BASE64):"
cat "$MACAROON_PATH" | base64 -w 0
echo ""
```

**Exécuter**:
```bash
chmod +x extract_credentials.sh
./extract_credentials.sh
```

**Copier les outputs** → Vous les utiliserez pour le `.env` du backend Lightning

---

## 🔧 Étape 3: Configurer le Backend Lightning

### 3.1 Fichier `.env` du Backend Lightning

Allez dans: `/home/iragame/apiLigthning/connect-lnd/`

**Créez ou modifiez `.env`:**

```bash
# Récupérez le port gRPC depuis Polar (généralement 10009, ou autre)
LND_GRPC_HOST=127.0.0.1:10009

# Macaroon en Base64 (du script précédent)
LND_MACAROON_BASE64=<COLLEZ_LE_MACAROON_BASE64_COMPLET>

# Certificate en Base64 (du script précédent)
LND_TLS_CERT_BASE64=<COLLEZ_LE_CERT_BASE64_COMPLET>

PORT=5003
```

### 3.2 Installer et Lancer le Backend Lightning

```bash
cd ~/apiLigthning/connect-lnd
npm install
npm start
```

**Vous devez voir**:
```
Successfully authenticated with LND node via ln-service!
Server running on port 5003
```

### 3.3 Tester la Connexion Lightning

```bash
curl http://localhost:5003/api/getinfo
```

**Réponse attendue**:
```json
{
  "alias": "alice",
  "public_key": "...",
  "version": "...",
  ...
}
```

✅ Si ça fonctionne, le backend Lightning est connecté!

---

## 💾 Étape 4: Vérifier la Configuration User Backend

### 4.1 Vérifier le `.env` du User Backend

```bash
cat ~/user-backend/.env
```

**Doit contenir**:
```
LIGHTNING_API_BASE_URL=http://localhost:5003/api
```

### 4.2 Vérifier la Base de Données

```bash
npm run migrate  # si un script existe
# ou

# Manually create tables
psql postgresql://postgres:postgres@localhost:5433/lightning_wallet -f sql/schema.sql
```

### 4.3 Lancer le User Backend

**Terminal séparé**:
```bash
cd ~/user-backend
npm install
npm start
```

**Vous devez voir**:
```
User backend running on http://localhost:7000
```

---

## ✅ Étape 5: Tester les Endpoints Lightning

### 5.1 Health Check

```bash
curl http://localhost:7000/health
```

**Réponse**:
```json
{ "success": true, "message": "User backend is running." }
```

### 5.2 Créer un Compte

```bash
curl -X POST http://localhost:7000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "email": "alice@test.com",
    "phone": "+33612345671",
    "password": "Test123!"
  }'
```

**Réponse**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "alice",
    "email": "alice@test.com",
    "balance_sats": 0,
    "created_at": "2026-05-28T..."
  }
}
```

### 5.3 Connexion

```bash
curl -X POST http://localhost:7000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@test.com",
    "password": "Test123!"
  }'
```

**Réponse** (sauvegardez le TOKEN):
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "username": "alice",
      "email": "alice@test.com",
      "balance_sats": 0
    }
  }
}
```

### 5.4 Créer une Invoice Lightning ⚡

```bash
# Utilisez le TOKEN du login précédent
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X POST http://localhost:7000/api/request-payment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "amountSats": 1000,
    "description": "Paiement de test"
  }'
```

**Réponse**:
```json
{
  "success": true,
  "data": {
    "paymentId": 1,
    "amountSats": 1000,
    "bolt11": "lnbc10000n1pj5dq...",
    "qrValue": "lnbc10000n1pj5dq...",
    "status": "pending"
  }
}
```

✅ **Sauvegardez le `bolt11`** - c'est la facture à payer!

---

## 🔄 Étape 6: Payer une Facture (Simulation Complète)

### 6.1 Créer une facture depuis un 2e nœud LND

Utilisez un autre nœud LND (ex: bob) ou utilisez un wallet externe comme **Bluewallet** ou **Umbrel**.

**Via ln-cli** (depuis Polar ou directement):
```bash
# Depuis le nœud alice, créer une invoice
lncli -n alice invoices add --amt 1000

# Depuis le nœud bob, payer cette invoice
lncli -n bob payinvoice <BOLT11>
```

### 6.2 Payer depuis l'API User Backend

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
BOLT11="lnbc10000n1pj5dq..."  # Une facture créée par un autre nœud

curl -X POST http://localhost:7000/api/send-payment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"paymentRequest\": \"$BOLT11\"
  }"
```

**Réponse**:
```json
{
  "success": true,
  "data": {
    "id": 2,
    "type": "send",
    "amount_sats": 1000,
    "status": "completed",
    "created_at": "2026-05-28T..."
  }
}
```

---

## 📊 Étape 7: Test Complet - Flux Réaliste

### Scénario: Alice reçoit → Bob paie

**Alice (User Backend)**:
1. S'enregistre
2. Se connecte
3. Crée une invoice de 500 sats

**Bob (Nœud LND via Polar)**:
1. Récupère le bolt11 d'Alice
2. Paie l'invoice

**Alice (vérification)**:
1. Consulte `/api/history`
2. Voit la transaction reçue
3. Solde augmenté!

### Code Complet de Test

```bash
#!/bin/bash

echo "=== Test Complet Lightning Custodial Wallet ==="

# 1. REGISTER US ER
echo -e "\n1️⃣  Registering alice..."
REGISTER=$(curl -s -X POST http://localhost:7000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "email": "alice@test.com",
    "password": "Test123!",
    "phone": "+33612345671"
  }')

echo "$REGISTER" | jq .

# 2. LOGIN
echo -e "\n2️⃣  Logging in..."
LOGIN=$(curl -s -X POST http://localhost:7000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@test.com",
    "password": "Test123!"
  }')

TOKEN=$(echo "$LOGIN" | jq -r '.data.token')
echo "Token: $TOKEN"

# 3. GET USER INFO
echo -e "\n3️⃣  Getting user info..."
curl -s -X GET http://localhost:7000/api/me \
  -H "Authorization: Bearer $TOKEN" | jq .

# 4. CREATE INVOICE
echo -e "\n4️⃣  Creating Lightning invoice..."
INVOICE=$(curl -s -X POST http://localhost:7000/api/request-payment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "amountSats": 500,
    "description": "Test payment"
  }')

PAYMENT_ID=$(echo "$INVOICE" | jq -r '.data.paymentId')
BOLT11=$(echo "$INVOICE" | jq -r '.data.bolt11')

echo "Invoice created!"
echo "Payment ID: $PAYMENT_ID"
echo "BOLT11: $BOLT11"

# 5. CHECK PAYMENT STATUS
echo -e "\n5️⃣  Checking payment status (should be pending)..."
curl -s -X GET http://localhost:7000/api/check-payment/$PAYMENT_ID \
  -H "Authorization: Bearer $TOKEN" | jq .

# 6. GET HISTORY
echo -e "\n6️⃣  Getting transaction history..."
curl -s -X GET "http://localhost:7000/api/history?limit=10&offset=0" \
  -H "Authorization: Bearer $TOKEN" | jq .

echo -e "\n✅ Test complete!"
echo "💡 Now pay the invoice in Polar or use LND CLI:"
echo "   lncli -n bob payinvoice $BOLT11"
```

**Exécuter**:
```bash
chmod +x test_lightning.sh
./test_lightning.sh
```

---

## 🔌 Étape 8: Communication Entre Nœuds

### Créer des canaux entre les nœuds (dans Polar)

1. **Cliquez sur le premier nœud** (alice)
2. **Tab "Connect"** → **"Open Channel"**
3. **Sélectionnez le nœud destination** (bob)
4. **Montant**: 100000 sats
5. ⏳ Attendez la confirmation blockchain

### Vérifier les canaux

```bash
curl http://localhost:5003/api/channels
```

---

## 🐛 Troubleshooting

### ❌ "Failed to connect to LND"

- Vérifiez que Polar est lancé et en statut **green**
- Vérifiez que `LND_GRPC_HOST` pointe au bon port (10009 par défaut)
- Vérifiez que le macaroon et cert sont encodés correctement en base64

### ❌ "LIGHTNING_API_BASE_URL connection refused"

- Vérifiez que le backend Lightning est lancé: `npm start` dans `/apiLigthning/connect-lnd`
- Vérifiez que le port 5003 est correct

### ❌ "VALIDATION_ERROR: expected object, received undefined"

- Dans Postman/curl: Vérifiez que `Content-Type: application/json` est présent
- Vérifiez que le body n'est pas vide

### ❌ "Transaction trouvée mais status pending"

- Les paiements Lightning demandent quelques secondes pour se confirmer
- Attendez 2-3 secondes puis vérifiez à nouveau avec `/api/check-payment/:id`

### ❌ "Insufficient balance"

- Vérifiez que votre nœud a du balance on-chain
- Utilisez Polar pour envoyer des sats on-chain au wallet du nœud

---

## 📈 Monitoring en Temps Réel

### Voir les logs du Backend Lightning

```bash
# Dans le terminal du backend Lightning
tail -f logs/lightning.log
```

### Voir les logs de PostgreSQL

```bash
tail -f ~/.psql_history
```

### Monitorer les transactions

```bash
# Dans une boucle
watch -n 1 'curl -s http://localhost:7000/api/history | jq .data[0]'
```

---

## ✨ Prochaines Étapes

Après validation des tests Lightning:

1. **Créer le Dashboard Admin** (React + Tailwind)
   - Voir toutes les transactions
   - Gérer les utilisateurs
   - Visualiser les balances

2. **Développer l'App Mobile** (Flutter)
   - UI pour créer des invoices
   - Scanner QR Code BOLT11
   - Affichage du solde en temps réel

3. **Déployer** (sur serveur VPS ou cloud)
   - Configurer un vrai nœud LND
   - Metrics et monitoring (Prometheus)
   - Alertes et notifications

---

## 📚 Ressources Utiles

- **Polar Docs**: https://docs.getpolar.sh/
- **ln-service**: https://github.com/alexbosworth/ln-service
- **LND Documentation**: https://docs.lightning.engineering/
- **Bitcoin Dev Kit**: https://bitcoindevkit.org/

---

## 🎯 Checklist Final

- [ ] Polar lancé avec 2+ nœuds LND
- [ ] Backend Lightning connecté à LND
- [ ] User Backend connecté à PostgreSQL
- [ ] `/health` endpoint répond
- [ ] Registration fonctionne
- [ ] Login fonctionne et retourne un token
- [ ] Invoice créée avec BOLT11 valide
- [ ] Paiement effectué depuis un autre nœud
- [ ] Historique affiche la transaction
- [ ] Solde mis à jour correctement

✅ Tous les points vérifiés? Vous êtes prêt pour la démo finale! 🚀
