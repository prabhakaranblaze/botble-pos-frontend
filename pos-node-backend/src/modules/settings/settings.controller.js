const settingsService = require('./settings.service');

class SettingsController {
  /**
   * GET /settings
   * Get POS settings including currency
   */
  async getSettings(req, res, next) {
    try {
      const settings = await settingsService.getSettings();

      res.json({
        error: false,
        data: { settings },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SettingsController();
