const express = require('express');
const { z } = require('zod');
const db = require('../config/db');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { createInvoice, payInvoice } = require('../services/lightningClient');

const router = express.Router();

const requestPaymentSchema = z.object({
  amountSats: z.number().int().positive(),
  description: z.string().max(255).optional()
});

const sendPaymentSchema = z.object({
  paymentRequest: z.string().min(10)
});

router.post('/request-payment', authenticate, validate(requestPaymentSchema), async (req, res, next) => {
  try {
    const { amountSats, description } = req.body;
    const invoice = await createInvoice(amountSats, description);

    const result = await db.query(
      `INSERT INTO transactions (user_id, type, amount_sats, payment_request, status, lnd_invoice_id, metadata)
       VALUES ($1, 'receive', $2, $3, 'pending', $4, $5::jsonb)
       RETURNING id, user_id, type, amount_sats, payment_request, status, lnd_invoice_id, created_at`,
      [
        req.user.id,
        amountSats,
        invoice.request,
        invoice.id || null,
        JSON.stringify({ description: description || '', invoiceExpiresAt: invoice.expires_at || null })
      ]
    );

    return res.status(201).json({
      success: true,
      data: {
        paymentId: result.rows[0].id,
        amountSats,
        bolt11: invoice.request,
        qrValue: invoice.request,
        status: 'pending'
      }
    });
  } catch (error) {
    return next(error);
  }
});

router.get('/check-payment/:id', authenticate, async (req, res, next) => {
  try {
    const paymentId = Number(req.params.id);
    if (!Number.isInteger(paymentId) || paymentId <= 0) {
      return res.status(400).json({ success: false, error: { code: 'INVALID_ID', message: 'ID invalide.' } });
    }

    const result = await db.query(
      `SELECT id, user_id, amount_sats, payment_request, status, created_at
       FROM transactions
       WHERE id = $1 AND user_id = $2 AND type = 'receive'`,
      [paymentId, req.user.id]
    );

    if (!result.rows.length) {
      return res.status(404).json({ success: false, error: { code: 'PAYMENT_NOT_FOUND', message: 'Paiement introuvable.' } });
    }

    return res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    return next(error);
  }
});

router.post('/send-payment', authenticate, validate(sendPaymentSchema), async (req, res, next) => {
  try {
    const { paymentRequest } = req.body;

    const pendingPayment = await payInvoice(paymentRequest);
    const amountSats = Number(pendingPayment?.payment_info?.tokens || pendingPayment?.payment_info?.safe_tokens || 0);

    if (!amountSats || amountSats <= 0) {
      return res.status(400).json({
        success: false,
        error: { code: 'PAYMENT_AMOUNT_UNKNOWN', message: 'Impossible de determiner le montant de la facture externe.' }
      });
    }

    const txResult = await db.withTransaction(async (client) => {
      const userRow = await client.query(`SELECT id, balance_sats FROM users WHERE id = $1 FOR UPDATE`, [req.user.id]);
      if (!userRow.rows.length) {
        const err = new Error('Utilisateur introuvable.');
        err.status = 404;
        err.code = 'USER_NOT_FOUND';
        throw err;
      }

      if (Number(userRow.rows[0].balance_sats) < amountSats) {
        const err = new Error('Solde insuffisant.');
        err.status = 400;
        err.code = 'INSUFFICIENT_BALANCE';
        throw err;
      }

      await client.query(`UPDATE users SET balance_sats = balance_sats - $1 WHERE id = $2`, [amountSats, req.user.id]);
      const inserted = await client.query(
        `INSERT INTO transactions (user_id, type, amount_sats, payment_request, status, metadata)
         VALUES ($1, 'send_external', $2, $3, 'completed', $4::jsonb)
         RETURNING id, amount_sats, status, created_at`,
        [req.user.id, amountSats, paymentRequest, JSON.stringify(pendingPayment)]
      );
      return inserted.rows[0];
    });

    return res.status(201).json({ success: true, data: txResult });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
