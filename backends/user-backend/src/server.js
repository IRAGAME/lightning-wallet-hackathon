const app = require('./app');
const env = require('./config/env');
const { query, pool } = require('./config/db');
const { startPaymentSync } = require('./services/paymentSync');

async function start() {
  await query('SELECT 1');
  app.listen(env.port, () => {
    console.log(`User backend running on http://localhost:${env.port}`);
  });
  startPaymentSync();
}

start().catch((error) => {
  console.error('Failed to start server:', error.message);
  process.exit(1);
});

process.on('SIGINT', async () => {
  await pool.end();
  process.exit(0);
});
