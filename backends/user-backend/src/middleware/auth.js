const jwt = require('jsonwebtoken');
const env = require('../config/env');

function authenticate(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    return res.status(401).json({ success: false, error: { code: 'UNAUTHORIZED', message: 'Token manquant.' } });
  }

  try {
    const payload = jwt.verify(token, env.jwtSecret);
    req.user = { id: payload.sub, username: payload.username };
    return next();
  } catch (error) {
    return res.status(401).json({ success: false, error: { code: 'INVALID_TOKEN', message: 'Token invalide ou expire.' } });
  }
}

module.exports = { authenticate };
