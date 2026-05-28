function validate(schema) {
  return (req, res, next) => {
    if (!req.body || Object.keys(req.body).length === 0) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Request body is empty. Make sure to send JSON data with Content-Type: application/json header.'
        }
      });
    }

    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: result.error.issues[0]?.message || 'Donnees invalides.'
        }
      });
    }
    req.body = result.data;
    return next();
  };
}

module.exports = { validate };
