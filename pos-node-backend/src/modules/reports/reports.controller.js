const reportsService = require('./reports.service');

class ReportsController {
  /**
   * GET /reports/orders
   * Get orders report with date filtering
   */
  async getOrdersReport(req, res, next) {
    try {
      const userId = req.user.id;
      const { from_date, to_date } = req.query;

      const data = await reportsService.getOrdersReport(userId, {
        fromDate: from_date,
        toDate: to_date,
      });

      res.json({
        error: false,
        message: 'Orders report loaded',
        data,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /reports/products
   * Get products sold report with date filtering and sorting
   */
  async getProductsReport(req, res, next) {
    try {
      const userId = req.user.id;
      const { from_date, to_date, sort_by, sort_order } = req.query;

      const data = await reportsService.getProductsReport(userId, {
        fromDate: from_date,
        toDate: to_date,
        sortBy: sort_by || 'quantity',
        sortOrder: sort_order || 'desc',
      });

      res.json({
        error: false,
        message: 'Products report loaded',
        data,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReportsController();
