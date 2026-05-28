const path = require('path');
const dotenv = require('dotenv');

dotenv.config({
  path: path.resolve(__dirname, '../../.env')
});

const required = ['DATABASE_URL', 'JWT_SECRET', 'LIGHTNING_API_BASE_URL'];

for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}

module.exports = {
  port: Number(process.env.PORT || 7000),
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  lightningApiBaseUrl: process.env.LIGHTNING_API_BASE_URL,
  paymentSyncIntervalMs: Number(process.env.PAYMENT_SYNC_INTERVAL_MS || 10000),
  corsOrigin: process.env.CORS_ORIGIN || '*'
};
