/**
 * Updates Routes
 * Endpoints for app version checking and updates
 */

const express = require('express');
const router = express.Router();
const updatesService = require('./updates.service');

/**
 * GET /updates/latest
 * Get the latest version information
 */
router.get('/latest', (req, res) => {
  try {
    const latestVersion = updatesService.getLatestVersion();

    res.json({
      error: false,
      message: 'Latest version retrieved',
      data: latestVersion,
    });
  } catch (error) {
    console.error('❌ UPDATES: Error getting latest version:', error);
    res.status(500).json({
      error: true,
      message: 'Failed to get latest version',
    });
  }
});

/**
 * POST /updates/check
 * Check if an update is available for the given version
 *
 * Body: { version: "1.0.0" }
 */
router.post('/check', (req, res) => {
  try {
    const { version } = req.body;

    if (!version) {
      return res.status(400).json({
        error: true,
        message: 'Version is required',
      });
    }

    const updateInfo = updatesService.checkForUpdate(version);

    console.log(`📦 UPDATES: Version check - Current: ${version}, Latest: ${updateInfo.latest_version}, Update: ${updateInfo.update_available}`);

    res.json({
      error: false,
      message: updateInfo.update_available ? 'Update available' : 'App is up to date',
      data: updateInfo,
    });
  } catch (error) {
    console.error('❌ UPDATES: Error checking for update:', error);
    res.status(500).json({
      error: true,
      message: 'Failed to check for updates',
    });
  }
});

module.exports = router;
