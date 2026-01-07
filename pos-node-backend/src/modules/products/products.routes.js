const express = require('express');
const router = express.Router();
const productsController = require('./products.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

router.get('/', productsController.getProducts.bind(productsController));
router.post('/scan-barcode', productsController.scanBarcode.bind(productsController));
router.get('/categories', productsController.getCategories.bind(productsController));
router.get('/:id', productsController.getProduct.bind(productsController));

module.exports = router;
