const { prisma } = require('../../config/database');
const productsService = require('../products/products.service');

/**
 * In-memory cart storage (use Redis in production)
 * Key: `cart:${userId}` Value: Cart object
 */
const cartStore = new Map();

class CartService {
  /**
   * Get cart key for user
   */
  getCartKey(userId) {
    return `cart:${userId}`;
  }

  /**
   * Get cart for user
   */
  getCart(userId) {
    const key = this.getCartKey(userId);
    if (!cartStore.has(key)) {
      cartStore.set(key, this.createEmptyCart());
    }
    return cartStore.get(key);
  }

  /**
   * Create empty cart structure
   */
  createEmptyCart() {
    return {
      items: [],
      subtotal: 0,
      discount: 0,
      tax: 0,
      shipping_amount: 0,
      total: 0,
      payment_method: null,
      coupon_code: null,
      customer_id: null,
    };
  }

  /**
   * Add item to cart
   */
  async addToCart(userId, productId, quantity = 1, attributes = null) {
    const cart = this.getCart(userId);

    // Get product
    const product = await productsService.getProductById(productId);
    if (!product) {
      throw new Error('Product not found');
    }

    if (!product.is_available) {
      throw new Error('Product is not available');
    }

    // Check if product already in cart
    const existingIndex = cart.items.findIndex(
      (item) => item.id === productId && JSON.stringify(item.attributes) === JSON.stringify(attributes)
    );

    if (existingIndex >= 0) {
      // Update quantity
      cart.items[existingIndex].quantity += quantity;
    } else {
      // Add new item
      cart.items.push({
        id: product.id,
        name: product.name,
        sku: product.sku,
        price: product.final_price || product.price,
        quantity,
        image: product.image,
        attributes,
      });
    }

    // Recalculate totals
    this.recalculateTotals(cart);

    return this.formatCart(cart);
  }

  /**
   * Update cart item quantity
   */
  async updateCart(userId, productId, quantity) {
    const cart = this.getCart(userId);

    const itemIndex = cart.items.findIndex((item) => item.id === productId);

    if (itemIndex < 0) {
      throw new Error('Item not found in cart');
    }

    if (quantity <= 0) {
      // Remove item
      cart.items.splice(itemIndex, 1);
    } else {
      cart.items[itemIndex].quantity = quantity;
    }

    this.recalculateTotals(cart);
    return this.formatCart(cart);
  }

  /**
   * Remove item from cart
   */
  async removeFromCart(userId, productId) {
    const cart = this.getCart(userId);

    const itemIndex = cart.items.findIndex((item) => item.id === productId);

    if (itemIndex >= 0) {
      cart.items.splice(itemIndex, 1);
    }

    this.recalculateTotals(cart);
    return this.formatCart(cart);
  }

  /**
   * Clear cart
   */
  clearCart(userId) {
    const key = this.getCartKey(userId);
    cartStore.set(key, this.createEmptyCart());
    return true;
  }

  /**
   * Update payment method
   */
  updatePaymentMethod(userId, paymentMethod) {
    const cart = this.getCart(userId);
    cart.payment_method = paymentMethod;
    return this.formatCart(cart);
  }

  /**
   * Set customer for cart
   */
  setCustomer(userId, customerId) {
    const cart = this.getCart(userId);
    cart.customer_id = customerId;
    return this.formatCart(cart);
  }

  /**
   * Recalculate cart totals
   */
  recalculateTotals(cart) {
    cart.subtotal = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);

    // Tax calculation (15% default - adjust based on your needs)
    const taxRate = 0.15;
    cart.tax = cart.subtotal * taxRate;

    cart.total = cart.subtotal + cart.tax + cart.shipping_amount - cart.discount;
  }

  /**
   * Format cart for API response
   */
  formatCart(cart) {
    return {
      items: cart.items.map((item) => ({
        id: item.id,
        name: item.name,
        sku: item.sku,
        price: item.price,
        quantity: item.quantity,
        image: item.image,
      })),
      subtotal: Math.round(cart.subtotal * 100) / 100,
      discount: Math.round(cart.discount * 100) / 100,
      tax: Math.round(cart.tax * 100) / 100,
      shipping_amount: Math.round(cart.shipping_amount * 100) / 100,
      total: Math.round(cart.total * 100) / 100,
      payment_method: cart.payment_method,
      coupon_code: cart.coupon_code,
    };
  }

  /**
   * Get cart items (raw, for order creation)
   */
  getCartItems(userId) {
    const cart = this.getCart(userId);
    return cart.items;
  }

  /**
   * Get full cart data (raw)
   */
  getCartData(userId) {
    return this.getCart(userId);
  }
}

module.exports = new CartService();
