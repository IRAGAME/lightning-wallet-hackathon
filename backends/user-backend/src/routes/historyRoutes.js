const express = require('express');
const db = require('../config/db');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.get('/history', authenticate, async (req, res, next) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const offset = Math.max(Number(req.query.offset) || 0, 0);

    const result = await db.query(
      `SELECT id, type, amount_sats, payment_request, status, related_user_id, metadata, created_at
       FROM transactions
       WHERE user_id = $1
       ORDER BY id DESC
       LIMIT $2 OFFSET $3`,
      [req.user.id, limit, offset]
    );

    return res.json({ success: true, data: result.rows, pagination: { limit, offset } });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
