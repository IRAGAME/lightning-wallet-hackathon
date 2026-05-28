const express = require('express');
const { z } = require('zod');
const db = require('../config/db');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

const transferSchema = z.object({
  toUsername: z.string().min(3).max(50),
  amountSats: z.number().int().positive()
});

router.post('/transfer', authenticate, validate(transferSchema), async (req, res, next) => {
  try {
    const { toUsername, amountSats } = req.body;

    const response = await db.withTransaction(async (client) => {
      const senderResult = await client.query(
        `SELECT id, username, balance_sats FROM users WHERE id = $1 FOR UPDATE`,
        [req.user.id]
      );
      if (!senderResult.rows.length) {
        const err = new Error('Expediteur introuvable.');
        err.status = 404;
        err.code = 'SENDER_NOT_FOUND';
        throw err;
      }

      const receiverResult = await client.query(
        `SELECT id, username FROM users WHERE username = $1 FOR UPDATE`,
        [toUsername]
      );
      if (!receiverResult.rows.length) {
        const err = new Error('Destinataire introuvable.');
        err.status = 404;
        err.code = 'RECEIVER_NOT_FOUND';
        throw err;
      }

      const sender = senderResult.rows[0];
      const receiver = receiverResult.rows[0];

      if (sender.id === receiver.id) {
        const err = new Error('Transfert vers soi-meme interdit.');
        err.status = 400;
        err.code = 'SELF_TRANSFER';
        throw err;
      }

      if (Number(sender.balance_sats) < amountSats) {
        const err = new Error('Solde insuffisant.');
        err.status = 400;
        err.code = 'INSUFFICIENT_BALANCE';
        throw err;
      }

      await client.query(`UPDATE users SET balance_sats = balance_sats - $1 WHERE id = $2`, [amountSats, sender.id]);
      await client.query(`UPDATE users SET balance_sats = balance_sats + $1 WHERE id = $2`, [amountSats, receiver.id]);

      const debitTx = await client.query(
        `INSERT INTO transactions (user_id, related_user_id, type, amount_sats, status, metadata)
         VALUES ($1, $2, 'transfer_out', $3, 'completed', $4::jsonb)
         RETURNING id, type, amount_sats, status, created_at`,
        [sender.id, receiver.id, amountSats, JSON.stringify({ toUsername: receiver.username })]
      );

      await client.query(
        `INSERT INTO transactions (user_id, related_user_id, type, amount_sats, status, metadata)
         VALUES ($1, $2, 'transfer_in', $3, 'completed', $4::jsonb)`,
        [receiver.id, sender.id, amountSats, JSON.stringify({ fromUsername: sender.username })]
      );

      return debitTx.rows[0];
    });

    return res.status(201).json({ success: true, data: response });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
