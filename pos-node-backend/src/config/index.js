require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3001,
  nodeEnv: process.env.NODE_ENV || 'development',

  jwt: {
    secret: process.env.JWT_SECRET || 'fallback-secret-change-me',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },

  apiKey: process.env.API_KEY || '',

  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
  },

  cors: {
    origin: process.env.CORS_ORIGIN || '*',
  },

  printer: {
    type: process.env.PRINTER_TYPE || 'network',
    host: process.env.PRINTER_HOST || '192.168.1.100',
    port: parseInt(process.env.PRINTER_PORT) || 9100,
  },

  storageUrl: process.env.STORAGE_URL || 'https://stampsmart.test/storage',
};
