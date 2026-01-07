const express = require('express');
const router = express.Router();
const printerService = require('./printer.service');
const ordersService = require('../orders/orders.service');
const { verifyToken } = require('../../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

/**
 * POST /printer/print-receipt
 */
router.post('/print-receipt', async (req, res) => {
  try {
    const { order_id } = req.body;

    if (!order_id) {
      return res.status(400).json({
        error: true,
        message: 'Order ID is required',
      });
    }

    const order = await ordersService.getOrderById(order_id);
    if (!order) {
      return res.status(404).json({
        error: true,
        message: 'Order not found',
      });
    }

    const success = await printerService.printReceipt(order);

    res.json({
      error: !success,
      message: success ? 'Receipt printed' : 'Print failed',
    });
  } catch (error) {
    res.status(500).json({
      error: true,
      message: error.message,
    });
  }
});

/**
 * POST /printer/open-drawer
 */
router.post('/open-drawer', async (req, res) => {
  try {
    const success = await printerService.openCashDrawer();

    res.json({
      error: !success,
      message: success ? 'Cash drawer opened' : 'Failed to open drawer',
    });
  } catch (error) {
    res.status(500).json({
      error: true,
      message: error.message,
    });
  }
});

/**
 * POST /printer/test
 */
router.post('/test', async (req, res) => {
  try {
    const success = await printerService.printTestPage();

    res.json({
      error: !success,
      message: success ? 'Test page printed' : 'Print test failed',
    });
  } catch (error) {
    res.status(500).json({
      error: true,
      message: error.message,
    });
  }
});

module.exports = router;
