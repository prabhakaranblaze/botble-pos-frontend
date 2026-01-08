require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const cookieParser = require('cookie-parser');
const rateLimit = require('express-rate-limit');

const config = require('./config');
const { testConnection } = require('./config/database');
const { verifyApiKey } = require('./middleware/auth.middleware');
const { errorHandler, notFoundHandler } = require('./middleware/error.middleware');

// Import routes
const authRoutes = require('./modules/auth/auth.routes');
const productsRoutes = require('./modules/products/products.routes');
const cartRoutes = require('./modules/cart/cart.routes');
const ordersRoutes = require('./modules/orders/orders.routes');
const customersRoutes = require('./modules/customers/customers.routes');
const sessionsRoutes = require('./modules/sessions/sessions.routes');
const denominationsRoutes = require('./modules/denominations/denominations.routes');
const printerRoutes = require('./modules/printer/printer.routes');
const settingsRoutes = require('./modules/settings/settings.routes');
const discountsRoutes = require('./modules/discounts/discounts.routes');
const reportsRoutes = require('./modules/reports/reports.routes');
const updatesRoutes = require('./modules/updates/updates.routes');

// Initialize Express
const app = express();

// Security middleware
app.use(helmet());
app.use(cors({ origin: config.cors.origin, credentials: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // 1000 requests per window
  message: { error: true, message: 'Too many requests' },
});
app.use('/api/', limiter);

// Parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// Logging
if (config.nodeEnv === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Health check (no API key required)
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// API routes (require API key)
const apiRouter = express.Router();
apiRouter.use(verifyApiKey);

// Mount routes
apiRouter.use('/auth', authRoutes);
apiRouter.use('/products', productsRoutes);
apiRouter.use('/cart', cartRoutes);
apiRouter.use('/orders', ordersRoutes);
apiRouter.use('/customers', customersRoutes);
apiRouter.use('/sessions', sessionsRoutes);

// Deprecated: cash-registers endpoint - returns empty for backward compatibility
// Flutter app should skip register selection and go directly to open session
apiRouter.get('/cash-registers', (req, res) => {
  res.json({
    error: false,
    message: 'Register selection not required. Use /sessions/open directly.',
    data: { cash_registers: [] },
  });
});
apiRouter.use('/denominations', denominationsRoutes);
apiRouter.use('/printer', printerRoutes);
apiRouter.use('/settings', settingsRoutes);
apiRouter.use('/discounts', discountsRoutes);
apiRouter.use('/reports', reportsRoutes);
apiRouter.use('/updates', updatesRoutes);

// Mount API router
app.use('/api/v1/pos', apiRouter);

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Start server
async function startServer() {
  try {
    // Test database connection
    await testConnection();

    // Initialize printer (optional)
    try {
      const printerService = require('./modules/printer/printer.service');
      await printerService.initialize();
    } catch (err) {
      console.log('⚠️ Printer not available:', err.message);
    }

    // Start listening
    app.listen(config.port, () => {
      console.log(`
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║   🚀 POS Node.js Backend Started                      ║
║                                                       ║
║   Server:  http://localhost:${config.port}                   ║
║   API:     http://localhost:${config.port}/api/v1/pos        ║
║   Health:  http://localhost:${config.port}/health            ║
║   Mode:    ${config.nodeEnv.padEnd(11)}                          ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
