const express = require('express');
const router = express.Router();
const denominationsController = require('./denominations.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

router.get('/', denominationsController.getDenominations.bind(denominationsController));
router.get('/currencies', denominationsController.getCurrencies.bind(denominationsController));

module.exports = router;
