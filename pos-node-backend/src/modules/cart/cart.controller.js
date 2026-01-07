const cartService = require('./cart.service');
const { z } = require('zod');

const addToCartSchema = z.object({
  product_id: z.number().int().positive(),
  quantity: z.number().int().positive().default(1),
  attributes: z.record(z.number()).optional(),
});

const updateCartSchema = z.object({
  product_id: z.number().int().positive(),
  quantity: z.number().int().min(0),
});

const removeFromCartSchema = z.object({
  product_id: z.number().int().positive(),
});

const paymentMethodSchema = z.object({
  payment_method: z.enum(['cash', 'card']),
});

class CartController {
  /**
   * POST /cart/add
   */
  async addToCart(req, res, next) {
    try {
      const { product_id, quantity, attributes } = addToCartSchema.parse(req.body);
      const userId = req.user.id;

      const cart = await cartService.addToCart(userId, product_id, quantity, attributes);

      res.json({
        error: false,
        data: cart,
      });
    } catch (error) {
      if (error.message === 'Product not found') {
        return res.status(404).json({
          error: true,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /cart/update
   */
  async updateCart(req, res, next) {
    try {
      const { product_id, quantity } = updateCartSchema.parse(req.body);
      const userId = req.user.id;

      const cart = await cartService.updateCart(userId, product_id, quantity);

      res.json({
        error: false,
        data: cart,
      });
    } catch (error) {
      if (error.message === 'Item not found in cart') {
        return res.status(404).json({
          error: true,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /cart/remove
   */
  async removeFromCart(req, res, next) {
    try {
      const { product_id } = removeFromCartSchema.parse(req.body);
      const userId = req.user.id;

      const cart = await cartService.removeFromCart(userId, product_id);

      res.json({
        error: false,
        data: cart,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /cart/clear
   */
  async clearCart(req, res, next) {
    try {
      const userId = req.user.id;
      cartService.clearCart(userId);

      res.json({
        error: false,
        message: 'Cart cleared',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /cart/update-payment-method
   */
  async updatePaymentMethod(req, res, next) {
    try {
      const { payment_method } = paymentMethodSchema.parse(req.body);
      const userId = req.user.id;

      const cart = cartService.updatePaymentMethod(userId, payment_method);

      res.json({
        error: false,
        data: cart,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /cart
   */
  async getCart(req, res, next) {
    try {
      const userId = req.user.id;
      const cart = cartService.getCart(userId);

      res.json({
        error: false,
        data: cartService.formatCart(cart),
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CartController();
