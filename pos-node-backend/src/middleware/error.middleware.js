/**
 * Error handling middleware
 */
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Prisma errors
  if (err.code && err.code.startsWith('P')) {
    return res.status(400).json({
      error: true,
      message: 'Database error',
      ...(process.env.NODE_ENV === 'development' && { details: err.message }),
    });
  }

  // Validation errors (Zod)
  if (err.name === 'ZodError') {
    return res.status(422).json({
      error: true,
      message: 'Validation error',
      errors: err.errors.map((e) => ({
        field: e.path.join('.'),
        message: e.message,
      })),
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return res.status(401).json({
      error: true,
      message: err.message,
    });
  }

  // Default error
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    error: true,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

/**
 * Not found handler
 */
const notFoundHandler = (req, res) => {
  res.status(404).json({
    error: true,
    message: `Route ${req.method} ${req.path} not found`,
  });
};

module.exports = {
  errorHandler,
  notFoundHandler,
};
