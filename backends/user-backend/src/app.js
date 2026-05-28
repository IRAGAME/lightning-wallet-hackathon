const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const env = require('./config/env');
const authRoutes = require('./routes/authRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const transferRoutes = require('./routes/transferRoutes');
const historyRoutes = require('./routes/historyRoutes');
const { errorHandler } = require('./middleware/errorHandler');

const app = express();

app.use(helmet());
app.use(
  cors({
    origin: env.corsOrigin === '*' ? true : env.corsOrigin.split(',').map((x) => x.trim())
  })
);
app.use(express.json());
app.use(morgan('dev'));

app.get('/health', (req, res) => {
  res.json({ success: true, message: 'User backend is running.' });
});

app.use('/api', authRoutes);
app.use('/api', paymentRoutes);
app.use('/api', transferRoutes);
app.use('/api', historyRoutes);

app.use((req, res) => {
  res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: `Route ${req.method} ${req.path} not found.` } });
});

app.use(errorHandler);

module.exports = app;
