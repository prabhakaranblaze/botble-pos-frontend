const express = require('express');
const router = express.Router();
const sessionsController = require('./sessions.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

router.get('/active', sessionsController.getActiveSession.bind(sessionsController));
router.post('/open', sessionsController.openSession.bind(sessionsController));
router.post('/close', sessionsController.closeSession.bind(sessionsController));

module.exports = router;
