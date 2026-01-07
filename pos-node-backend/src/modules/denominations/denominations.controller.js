const denominationsService = require('./denominations.service');

class DenominationsController {
  /**
   * GET /denominations
   */
  async getDenominations(req, res, next) {
    try {
      const currency = req.query.currency || 'USD';
      const denominations = await denominationsService.getDenominations(currency);

      res.json({
        error: false,
        data: { denominations },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /denominations/currencies
   */
  async getCurrencies(req, res, next) {
    try {
      const currencies = await denominationsService.getAvailableCurrencies();

      res.json({
        error: false,
        data: { currencies },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new DenominationsController();
