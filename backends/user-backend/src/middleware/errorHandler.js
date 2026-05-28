function errorHandler(error, req, res, next) {
  const status = error.status || 500;
  const code = error.code || 'INTERNAL_ERROR';
  const message = error.message || 'Erreur interne.';

  if (status >= 500) {
    console.error('Unhandled error:', error);
  }

  res.status(status).json({
    success: false,
    error: { code, message }
  });
}

module.exports = { errorHandler };
