const axios = require('axios');
const env = require('../config/env');

const client = axios.create({
  baseURL: env.lightningApiBaseUrl,
  timeout: 15000
});

async function createInvoice(amountSats, description) {
  const { data } = await client.post('/invoice', {
    sats: amountSats,
    description: description || ''
  });
  return data;
}

async function payInvoice(request) {
  try {
    const { data } = await client.post('/pay', { request });
    return data;
  } catch (err) {
    if (err.response?.data) {
      const { error: errMsg, details } = err.response.data;
      const lnError = new Error(typeof errMsg === 'string' ? errMsg : 'Échec du paiement Lightning.');
      lnError.status = err.response.status;
      lnError.code = details?.[0] || 'LIGHTNING_ERROR';
      throw lnError;
    }
    throw err;
  }
}

async function listInvoices() {
  const { data } = await client.get('/invoices');
  return data;
}

module.exports = {
  createInvoice,
  payInvoice,
  listInvoices
};
