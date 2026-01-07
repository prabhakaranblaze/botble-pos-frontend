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
    options: z.string().optional().nullable(),
    tax_rate: z.number().optional().nullable(),
  })).min(1, 'Cart is empty'),
  payment_method: z.enum(['cash', 'card', 'pos_cash', 'pos_card']).default('pos_cash'),
  payment_details: z.string().optional().nullable(),
  customer_id: z.number().int().positive().optional().nullable(),
  // Discount parameters
  discount_id: z.number().int().positive().optional().nullable(),
  coupon_code: z.string().optional().nullable(),
  discount_amount: z.number().optional().default(0),
  discount_description: z.string().optional().nullable(),
  // Shipping
  shipping_amount: z.number().optional().default(0),
  // Tax
  tax_amount: z.number().optional().nullable(),
  // Customer info for invoice
  customer_name: z.string().optional().nullable(),
  customer_email: z.string().optional().nullable(),
  customer_phone: z.string().optional().nullable(),
});

class OrdersController {
  /**
   * GET /orders (list recent orders)
   */
  async getOrders(req, res, next) {
    try {
      const limit = parseInt(req.query.limit) || 20;
      const search = req.query.search || null;

      const orders = await ordersService.getRecentOrders({ limit, search });

      res.json({
        error: false,
        data: { orders },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /orders (checkout)
   * Accepts cart items directly from client - no server-side cart sync needed
   */
  async checkout(req, res, next) {
    try {
      console.log('========== CHECKOUT CONTROLLER ==========');
      console.log('req.body:', JSON.stringify(req.body, null, 2));
      console.log('req.body.tax_amount:', req.body.tax_amount);
      console.log('req.body.discount_amount:', req.body.discount_amount);
      console.log('req.body.shipping_amount:', req.body.shipping_amount);

      const data = checkoutSchema.parse(req.body);
      const userId = req.user.id;

      console.log('Parsed data.tax_amount:', data.tax_amount);
      console.log('Parsed data.discount_amount:', data.discount_amount);
      console.log('Parsed data.shipping_amount:', data.shipping_amount);

      const order = await ordersService.checkoutDirect(userId, {
        items: data.items,
        paymentMethod: data.payment_method,
        paymentDetails: data.payment_details,
        customerId: data.customer_id,
        // Discount parameters
        discountId: data.discount_id,
        couponCode: data.coupon_code,
        discountAmount: data.discount_amount,
        discountDescription: data.discount_description,
        // Shipping
        shippingAmount: data.shipping_amount,
        // Tax
        taxAmount: data.tax_amount,
        // Customer info for invoice
        customerName: data.customer_name,
        customerEmail: data.customer_email,
        customerPhone: data.customer_phone,
      });

      res.json({
        error: false,
        data: { order },
      });
    } catch (error) {
      console.error('Checkout error:', error);
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
