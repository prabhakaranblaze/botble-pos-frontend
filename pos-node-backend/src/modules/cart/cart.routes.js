const express = require('express');
const router = express.Router();
const cartController = require('./cart.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

router.get('/', cartController.getCart.bind(cartController));
router.post('/add', cartController.addToCart.bind(cartController));
router.post('/update', cartController.updateCart.bind(cartController));
router.post('/remove', cartController.removeFromCart.bind(cartController));
router.post('/clear', cartController.clearCart.bind(cartController));
router.post('/update-payment-method', cartController.updatePaymentMethod.bind(cartController));

module.exports = router;
