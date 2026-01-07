const express = require('express');
const router = express.Router();
const discountsController = require('./discounts.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

// Validate coupon code
router.post('/validate', discountsController.validateCoupon.bind(discountsController));

// Calculate manual discount
router.post('/calculate', discountsController.calculateDiscount.bind(discountsController));

module.exports = router;
