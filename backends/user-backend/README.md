# User Backend - Lightning Custodial MVP

Backend Node.js/Express pour gerer:

- inscription/connexion utilisateurs (JWT),
- balances internes en sats,
- demandes de paiement Lightning (QR/BOLT11),
- verification de paiement,
- transferts internes,
- paiements externes,
- historique de transactions.

Ce service s'appuie sur le backend Lightning existant (`connect-lnd`) via HTTP.

## 1) Installation

```bash
cd user-backend
npm install
cp .env.example .env
```

## 2) Initialiser PostgreSQL

Creer une base de donnees puis executer:

```bash
psql "$DATABASE_URL" -f sql/schema.sql
```

## 3) Demarrer

```bash
npm run dev
```

## 4) Endpoints MVP

- `POST /api/register`
- `POST /api/login`
- `GET /api/me`
- `POST /api/request-payment`
- `GET /api/check-payment/:id`
- `POST /api/transfer`
- `POST /api/send-payment`
- `GET /api/history?limit=50&offset=0`

## 5) Variables d'environnement

- `PORT` port du backend user
- `DATABASE_URL` connexion PostgreSQL
- `JWT_SECRET` secret JWT
- `JWT_EXPIRES_IN` duree token
- `LIGHTNING_API_BASE_URL` URL de l'API Lightning existante (ex: `http://localhost:5003/api`)
- `PAYMENT_SYNC_INTERVAL_MS` frequence de sync des invoices payees
- `CORS_ORIGIN` origine front autorisee (`*` ou CSV)
