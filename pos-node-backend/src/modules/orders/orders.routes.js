const express = require('express');
const router = express.Router();
const ordersController = require('./orders.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

router.get('/', ordersController.getOrders.bind(ordersController));
router.post('/', ordersController.checkout.bind(ordersController));
router.get('/:id', ordersController.getOrder.bind(ordersController));
router.get('/:id/receipt', ordersController.getReceipt.bind(ordersController));

module.exports = router;
