const express = require('express');
const { authenticatedLndGrpc } = require('ln-service');
const { pay } = require('ln-service');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let lnd;

function connectToBob() {
  const socket = process.env.BOB_GRPC_HOST;
  const macaroon = process.env.BOB_MACAROON_BASE64;
  const cert = process.env.BOB_TLS_CERT_BASE64;

  if (!socket || !macaroon || !cert) {
    console.error('Missing bob credentials in .env');
    process.exit(1);
  }

  const { lnd: bobLnd } = authenticatedLndGrpc({ socket, macaroon, cert });
  lnd = bobLnd;
  console.log('Bob connecté à LND!');
}

connectToBob();

app.post('/api/pay', async (req, res) => {
  try {
    const { invoice } = req.body;
    if (!invoice) {
      return res.status(400).json({ success: false, error: 'Invoice requis.' });
    }
    const result = await pay({ lnd, request: invoice });
    res.json({ success: true, data: result });
  } catch (err) {
    console.error('Erreur paiement bob:', err);
    res.status(500).json({ success: false, error: err.message || 'Échec du paiement.' });
  }
});

app.get('/api/info', async (req, res) => {
  try {
    const { getWalletInfo } = require('ln-service');
    const info = await getWalletInfo({ lnd });
    res.json({ success: true, data: info });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/decode', async (req, res) => {
  try {
    const { decodePaymentRequest } = require('ln-service');
    const decoded = await decodePaymentRequest({ request: req.query.invoice });
    res.json({ success: true, data: decoded });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

const PORT = process.env.PORT || 3004;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Bob-pay ready on http://0.0.0.0:${PORT}`);
});
