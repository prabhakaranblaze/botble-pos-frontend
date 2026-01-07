const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// Public routes
router.post('/login', authController.login.bind(authController));

// Protected routes
router.get('/me', verifyToken, authController.me.bind(authController));
router.post('/logout', verifyToken, authController.logout.bind(authController));

module.exports = router;
