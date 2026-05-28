const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const db = require('../config/db');
const env = require('../config/env');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

const registerSchema = z.object({
  username: z.string().min(3).max(50),
  email: z.string().email(),
  phone: z.string().max(20).optional(),
  password: z.string().min(6).max(128)
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6).max(128)
});

router.post('/register', validate(registerSchema), async (req, res, next) => {
  try {
    const { username, email, phone, password } = req.body;
    const hash = await bcrypt.hash(password, 10);

    const result = await db.query(
      `INSERT INTO users (username, email, phone, password_hash)
       VALUES ($1, $2, $3, $4)
       RETURNING id, username, email, phone, balance_sats, created_at`,
      [username, email.toLowerCase(), phone || null, hash]
    );

    return res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: { code: 'DUPLICATE_USER', message: 'Username ou email deja utilise.' }
      });
    }
    return next(error);
  }
});

router.post('/login', validate(loginSchema), async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const result = await db.query(
      `SELECT id, username, email, password_hash, balance_sats FROM users WHERE email = $1`,
      [email.toLowerCase()]
    );

    if (!result.rows.length) {
      return res.status(401).json({ success: false, error: { code: 'INVALID_CREDENTIALS', message: 'Identifiants invalides.' } });
    }

    const user = result.rows[0];
    const matches = await bcrypt.compare(password, user.password_hash);
    if (!matches) {
      return res.status(401).json({ success: false, error: { code: 'INVALID_CREDENTIALS', message: 'Identifiants invalides.' } });
    }

    const token = jwt.sign({ username: user.username }, env.jwtSecret, {
      subject: String(user.id),
      expiresIn: env.jwtExpiresIn
    });

    return res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          balance_sats: user.balance_sats
        }
      }
    });
  } catch (error) {
    return next(error);
  }
});

router.get('/me', authenticate, async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT id, username, email, phone, balance_sats, status, created_at FROM users WHERE id = $1`,
      [req.user.id]
    );
    if (!result.rows.length) {
      return res.status(404).json({ success: false, error: { code: 'USER_NOT_FOUND', message: 'Utilisateur introuvable.' } });
    }
    return res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
