require('dotenv').config();

// CDN URL for images (Cloudflare R2)
const cdnUrl = process.env.CDN_URL || 'https://pub-1664f164de65435e943bd597c050e247.r2.dev';

// Old storage URL patterns that need to be replaced
const oldStoragePatterns = [
  'https://stampsmart.test/storage',
  'http://stampsmart.test/storage',
  'https://stampsmart.sc/storage',
  'http://stampsmart.sc/storage',
];

/**
 * Transform image URL from old storage to CDN
 * Handles both full URLs and relative paths
 */
function transformImageUrl(url) {
  if (!url) return null;

  // Replace old storage URLs with CDN
  for (const pattern of oldStoragePatterns) {
    if (url.startsWith(pattern)) {
      return url.replace(pattern, cdnUrl);
    }
  }

  // If it's a relative path, prepend CDN URL
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    const cleanPath = url.startsWith('/') ? url.substring(1) : url;
    return `${cdnUrl}/${cleanPath}`;
  }

  // Return as-is if it's already a valid URL (e.g., already CDN URL)
  return url;
}

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
  cdnUrl,
  transformImageUrl,
};
