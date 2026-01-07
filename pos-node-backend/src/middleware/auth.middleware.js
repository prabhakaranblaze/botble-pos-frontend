const jwt = require('jsonwebtoken');
const config = require('../config');
const { prisma } = require('../config/database');

/**
 * Verify API Key middleware
 */
const verifyApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];

  if (!apiKey || apiKey !== config.apiKey) {
    return res.status(401).json({
      error: true,
      message: 'Invalid or missing API key',
    });
  }

  next();
};

/**
 * Verify JWT Token middleware
 */
const verifyToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: true,
        message: 'No token provided',
      });
    }

    const token = authHeader.split(' ')[1];

    // Verify JWT
    const decoded = jwt.verify(token, config.jwt.secret);

    // Get user from database
    const user = await prisma.user.findUnique({
      where: { id: BigInt(decoded.userId) },
      select: {
        id: true,
        email: true,
        first_name: true,
        last_name: true,
        username: true,
        store_id: true,
        super_user: true,
        permissions: true,
        deleted_at: true,
      },
    });

    if (!user || user.deleted_at) {
      return res.status(401).json({
        error: true,
        message: 'User not found or deactivated',
      });
    }

    // Attach user to request
    req.user = {
      id: Number(user.id),
      email: user.email,
      name: `${user.first_name || ''} ${user.last_name || ''}`.trim() || user.username,
      firstName: user.first_name,
      lastName: user.last_name,
      username: user.username,
      storeId: user.store_id ? Number(user.store_id) : null,
      isSuperUser: user.super_user,
      permissions: user.permissions ? JSON.parse(user.permissions) : {},
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: true,
        message: 'Token expired',
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: true,
        message: 'Invalid token',
      });
    }

    console.error('Auth middleware error:', error);
    return res.status(500).json({
      error: true,
      message: 'Authentication error',
    });
  }
};

/**
 * Check POS permission middleware
 */
const requirePosPermission = (req, res, next) => {
  const user = req.user;

  if (!user) {
    return res.status(401).json({
      error: true,
      message: 'Unauthorized',
    });
  }

  // Super users have all permissions
  if (user.isSuperUser) {
    return next();
  }

  // Check for POS permission
  const permissions = user.permissions || {};
  if (!permissions['pos.index'] && !permissions['pos-pro']) {
    return res.status(403).json({
      error: true,
      message: 'You do not have permission to access POS',
    });
  }

  next();
};

module.exports = {
  verifyApiKey,
  verifyToken,
  requirePosPermission,
};
