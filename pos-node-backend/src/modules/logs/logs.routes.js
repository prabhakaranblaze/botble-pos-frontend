const express = require('express');
const router = express.Router();

/**
 * POST /logs/report
 * Receive diagnostic logs from the Flutter client and print to console.
 * No auth token required (API key still required via apiRouter).
 */
router.post('/report', (req, res) => {
  const { deviceInfo, logContent, timestamp } = req.body;

  console.log('\n========== CLIENT LOG REPORT ==========');
  console.log(`Timestamp: ${timestamp || new Date().toISOString()}`);
  if (deviceInfo) {
    console.log(`Device: ${deviceInfo}`);
  }
  console.log('--- Log Content ---');
  console.log(logContent || '(empty)');
  console.log('========== END LOG REPORT ==========\n');

  res.json({
    error: false,
    message: 'Log report received',
  });
});

module.exports = router;
