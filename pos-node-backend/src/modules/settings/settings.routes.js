const express = require('express');
const router = express.Router();
const settingsController = require('./settings.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

router.get('/', settingsController.getSettings.bind(settingsController));

module.exports = router;
