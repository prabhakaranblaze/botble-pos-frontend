const express = require('express');
const router = express.Router();
const customersController = require('./customers.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

// Customer routes
router.get('/search', customersController.searchCustomers.bind(customersController));
router.post('/', customersController.createCustomer.bind(customersController));
router.get('/:id', customersController.getCustomer.bind(customersController));

// Address routes
router.get('/:id/addresses', customersController.getCustomerAddresses.bind(customersController));
router.post('/:id/addresses', customersController.createCustomerAddress.bind(customersController));
router.get('/addresses/:addressId', customersController.getAddress.bind(customersController));

module.exports = router;
