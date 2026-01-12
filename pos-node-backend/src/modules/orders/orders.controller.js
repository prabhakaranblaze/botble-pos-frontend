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
  payment_metadata: z.record(z.any()).optional().nullable(), // JSON object for cash/card details
  customer_id: z.number().int().positive().optional().nullable(),
  // Discount parameters
  discount_id: z.number().int().positive().optional().nullable(),
  coupon_code: z.string().optional().nullable(),
  discount_amount: z.number().optional().default(0),
  discount_description: z.string().optional().nullable(),
  // Shipping
  shipping_amount: z.number().optional().default(0),
  delivery_type: z.enum(['pickup', 'ship']).optional().default('pickup'),
  // Tax
  tax_amount: z.number().optional().nullable(),
  // Customer info for invoice
  customer_name: z.string().optional().nullable(),
  customer_email: z.string().optional().nullable(),
  customer_phone: z.string().optional().nullable(),
  // Address info (for delivery_type = 'ship')
  address_id: z.number().int().positive().optional().nullable(),
  customer_address: z.string().optional().nullable(), // Full formatted address for invoice
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
        paymentMetadata: data.payment_metadata,
        customerId: data.customer_id,
        // Discount parameters
        discountId: data.discount_id,
        couponCode: data.coupon_code,
        discountAmount: data.discount_amount,
        discountDescription: data.discount_description,
        // Shipping
        shippingAmount: data.shipping_amount,
        deliveryType: data.delivery_type,
        // Tax
        taxAmount: data.tax_amount,
        // Customer info for invoice
        customerName: data.customer_name,
        customerEmail: data.customer_email,
        customerPhone: data.customer_phone,
        // Address info
        addressId: data.address_id,
        customerAddress: data.customer_address,
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

  /**
   * POST /orders/laravel-checkout
   * Proxy checkout to Laravel API with POS_API_TOKEN authentication
   * This allows Laravel to handle order creation while Node.js handles POS auth
   */
  async checkoutViaLaravel(req, res, next) {
    try {
      console.log('========== LARAVEL CHECKOUT PROXY ==========');

      const laravelApiUrl = process.env.LARAVEL_API_URL;
      const laravelApiKey = process.env.LARAVEL_API_KEY;
      const posApiToken = process.env.POS_API_TOKEN;

      if (!laravelApiUrl || !posApiToken) {
        console.error('Missing Laravel API configuration');
        return res.status(500).json({
          error: true,
          message: 'Laravel API not configured',
        });
      }

      // Get user info from Node.js auth
      const posUser = req.user;
      console.log('POS User:', posUser.id, posUser.username);

      // Build cart payload for Laravel
      const cartData = req.body.cart || req.body;
      const payload = {
        pos_user_id: posUser.id,
        pos_username: posUser.username || posUser.email,
        customer_id: req.body.customer_id || null,
        address: req.body.address || {
          address_id: 'new',
          name: req.body.customer_name || 'Guest',
          email: req.body.customer_email || 'guest@example.com',
          phone: req.body.customer_phone || 'N/A',
          country: 'SC',
          state: null,
          city: null,
          address: 'Pickup at Store',
          zip_code: null,
        },
        delivery_option: req.body.delivery_option || req.body.delivery_type || 'pickup',
        payment_method: req.body.payment_method || 'cash',
        notes: req.body.notes || null,
        cash_received: req.body.cash_received || null,
        cart: {
          items: (cartData.items || []).map(item => ({
            id: item.product_id || item.id,
            name: item.name,
            sku: item.sku || null,
            image: item.image || null,
            price: item.price,
            quantity: item.quantity,
            tax_rate: item.tax_rate || 0,
            attributes: item.attributes || item.options || null,
            image_url: item.image_url || null,
          })),
          subtotal: cartData.subtotal || cartData.sub_total || 0,
          subtotal_formatted: cartData.subtotal_formatted || '',
          coupon_code: cartData.coupon_code || null,
          coupon_discount: cartData.coupon_discount || 0,
          coupon_discount_formatted: cartData.coupon_discount_formatted || '',
          coupon_discount_type: cartData.coupon_discount_type || null,
          manual_discount: cartData.manual_discount || 0,
          manual_discount_value: cartData.manual_discount_value || 0,
          manual_discount_type: cartData.manual_discount_type || 'fixed',
          manual_discount_formatted: cartData.manual_discount_formatted || '',
          manual_discount_description: cartData.manual_discount_description || '',
          tax: cartData.tax || cartData.tax_amount || 0,
          tax_formatted: cartData.tax_formatted || '',
          tax_details: cartData.tax_details || [],
          shipping_amount: cartData.shipping_amount || 0,
          shipping_amount_formatted: cartData.shipping_amount_formatted || '',
          total: cartData.total || 0,
          total_formatted: cartData.total_formatted || '',
          count: (cartData.items || []).length,
          customer_id: req.body.customer_id || null,
          customer: req.body.customer || null,
          payment_method: req.body.payment_method || 'cash',
          payment_method_enum: req.body.payment_method === 'card' ? 'pos_card' : 'pos_cash',
        },
      };

      console.log('Sending to Laravel:', JSON.stringify(payload, null, 2));

      // Call Laravel API
      const response = await axios.post(
        `${laravelApiUrl}/checkout/processcheckout`,
        payload,
        {
          headers: {
            'Content-Type': 'application/json',
            'X-API-KEY': laravelApiKey,
            'Token': posApiToken,
          },
          timeout: 30000, // 30 second timeout
        }
      );

      console.log('Laravel response:', JSON.stringify(response.data, null, 2));

      // Return Laravel response to client
      res.json(response.data);

    } catch (error) {
      console.error('Laravel checkout error:', error.message);

      if (error.response) {
        // Laravel returned an error response
        console.error('Laravel error response:', error.response.data);
        return res.status(error.response.status).json({
          error: true,
          message: error.response.data?.message || 'Laravel checkout failed',
          details: error.response.data,
        });
      }

      if (error.code === 'ECONNREFUSED') {
        return res.status(503).json({
          error: true,
          message: 'Laravel API unavailable',
        });
      }

      next(error);
    }
  }
}

module.exports = new OrdersController();
