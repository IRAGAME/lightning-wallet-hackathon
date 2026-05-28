const { listInvoices } = require('./lightningClient');
const db = require('../config/db');
const env = require('../config/env');

function invoiceIsPaid(invoice) {
  return Boolean(
    invoice.is_confirmed ||
      invoice.is_paid ||
      invoice.confirmed_at ||
      invoice.received ||
      invoice.received_mtokens
  );
}

async function syncPaidInvoices() {
  const pendingRows = await db.query(
    `SELECT t.id, t.user_id, t.amount_sats, t.payment_request, t.lnd_invoice_id
     FROM transactions t
     WHERE t.type = 'receive' AND t.status = 'pending'
     ORDER BY t.id ASC`
  );

  if (!pendingRows.rows.length) {
    return;
  }

  const invoices = await listInvoices();
  if (!Array.isArray(invoices) || invoices.length === 0) {
    return;
  }

  for (const tx of pendingRows.rows) {
    const matched = invoices.find((inv) => {
      const sameById = tx.lnd_invoice_id && inv.id && tx.lnd_invoice_id === inv.id;
      const sameByRequest = tx.payment_request && inv.request && tx.payment_request === inv.request;
      return sameById || sameByRequest;
    });

    if (!matched || !invoiceIsPaid(matched)) {
      continue;
    }

    await db.withTransaction(async (client) => {
      const lockTx = await client.query(
        `SELECT id, status FROM transactions WHERE id = $1 FOR UPDATE`,
        [tx.id]
      );

      if (!lockTx.rows.length || lockTx.rows[0].status === 'completed') {
        return;
      }

      await client.query(
        `UPDATE users SET balance_sats = balance_sats + $1 WHERE id = $2`,
        [tx.amount_sats, tx.user_id]
      );

      await client.query(
        `UPDATE transactions
         SET status = 'completed',
             metadata = jsonb_set(COALESCE(metadata, '{}'::jsonb), '{paidAt}', to_jsonb(NOW()::text))
         WHERE id = $1`,
        [tx.id]
      );
    });
  }
}

function startPaymentSync() {
  setInterval(async () => {
    try {
      await syncPaidInvoices();
    } catch (error) {
      console.error('Payment sync error:', error.message);
    }
  }, env.paymentSyncIntervalMs);
}

module.exports = { startPaymentSync, syncPaidInvoices };
