const express = require('express');
const router = express.Router();
const reportsController = require('./reports.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// All report routes require authentication
router.use(verifyToken);

/**
 * GET /reports/orders
 * Get orders report with date filtering
 * Query params: from_date, to_date (YYYY-MM-DD format)
 */
router.get('/orders', reportsController.getOrdersReport.bind(reportsController));

/**
 * GET /reports/products
 * Get products sold report with date filtering and sorting
 * Query params: from_date, to_date, sort_by (quantity|revenue|name), sort_order (asc|desc)
 */
router.get('/products', reportsController.getProductsReport.bind(reportsController));

module.exports = router;
