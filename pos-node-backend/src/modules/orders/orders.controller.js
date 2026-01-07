const ordersService = require('./orders.service');
const { z } = require('zod');

const checkoutSchema = z.object({
  payment_details: z.string().optional(),
});

class OrdersController {
  /**
   * POST /orders (checkout)
   */
  async checkout(req, res, next) {
    try {
      const { payment_details } = checkoutSchema.parse(req.body);
      const userId = req.user.id;

      const order = await ordersService.checkout(userId, payment_details);

      res.json({
        error: false,
        data: { order },
      });
    } catch (error) {
      if (error.message === 'Cart is empty') {
        return res.status(400).json({
          error: true,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * GET /orders/:id
   */
  async getOrder(req, res, next) {
    try {
      const order = await ordersService.getOrderById(req.params.id);

      if (!order) {
        return res.status(404).json({
          error: true,
          message: 'Order not found',
        });
      }

      res.json({
        error: false,
        data: { order },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /orders/:id/receipt
   */
  async getReceipt(req, res, next) {
    try {
      const receiptHtml = await ordersService.getReceipt(req.params.id);

      res.json({
        error: false,
        data: { receipt_html: receiptHtml },
      });
    } catch (error) {
      if (error.message === 'Order not found') {
        return res.status(404).json({
          error: true,
          message: error.message,
        });
      }
      next(error);
    }
  }
}

module.exports = new OrdersController();
