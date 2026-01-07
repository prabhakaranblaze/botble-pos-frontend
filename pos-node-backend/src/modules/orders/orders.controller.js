const ordersService = require('./orders.service');
const { z } = require('zod');

// Schema for direct checkout (items sent from client)
// Accepts both legacy (cash/card) and Laravel-style (pos_cash/pos_card) payment methods
const checkoutSchema = z.object({
  items: z.array(z.object({
    product_id: z.number().int().positive(),
    name: z.string(),
    quantity: z.number().int().positive(),
    price: z.number().positive(),
    image: z.string().optional().nullable(),
    sku: z.string().optional().nullable(),
  })).min(1, 'Cart is empty'),
  payment_method: z.enum(['cash', 'card', 'pos_cash', 'pos_card']).default('pos_cash'),
  payment_details: z.string().optional().nullable(),
  customer_id: z.number().int().positive().optional().nullable(),
});

class OrdersController {
  /**
   * POST /orders (checkout)
   * Accepts cart items directly from client - no server-side cart sync needed
   */
  async checkout(req, res, next) {
    try {
      const data = checkoutSchema.parse(req.body);
      const userId = req.user.id;

      const order = await ordersService.checkoutDirect(userId, {
        items: data.items,
        paymentMethod: data.payment_method,
        paymentDetails: data.payment_details,
        customerId: data.customer_id,
      });

      res.json({
        error: false,
        data: { order },
      });
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({
          error: true,
          message: error.errors[0]?.message || 'Invalid request data',
        });
      }
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
