const express = require('express');
const router = express.Router();
const customersController = require('./customers.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

router.get('/search', customersController.searchCustomers.bind(customersController));
router.post('/', customersController.createCustomer.bind(customersController));
router.get('/:id', customersController.getCustomer.bind(customersController));

module.exports = router;
