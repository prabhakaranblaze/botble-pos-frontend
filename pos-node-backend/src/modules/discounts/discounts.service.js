const { prisma } = require('../../config/database');

class DiscountsService {
  /**
   * Validate and apply a coupon code
   * @param {string} code - Coupon code
   * @param {number} subtotal - Cart subtotal
   * @param {Array} items - Cart items with product_id, quantity, price
   * @param {number|null} customerId - Customer ID (optional)
   * @returns {Object} - Validation result with discount amount
   */
  async validateCoupon(code, subtotal, items = [], customerId = null) {
    if (!code || code.trim() === '') {
      return { valid: false, message: 'Coupon code is required' };
    }

    // Find the discount by code
    const discount = await prisma.discount.findFirst({
      where: {
        code: code.trim(),
        deleted_at: null,
      },
      include: {
        discountCustomers: true,
        discountProducts: true,
      },
    });

    if (!discount) {
      return { valid: false, message: 'Invalid coupon code' };
    }

    // Check date validity
    const now = new Date();
    if (discount.start_date && new Date(discount.start_date) > now) {
      return { valid: false, message: 'This coupon is not yet active' };
    }
    if (discount.end_date && new Date(discount.end_date) < now) {
      return { valid: false, message: 'This coupon has expired' };
    }

    // Check usage limit
    if (discount.quantity !== null && discount.total_used >= discount.quantity) {
      return { valid: false, message: 'This coupon has reached its usage limit' };
    }

    // Check minimum order price
    if (discount.min_order_price && subtotal < Number(discount.min_order_price)) {
      const minAmount = Number(discount.min_order_price);
      return {
        valid: false,
        message: `Minimum order amount is ${minAmount.toFixed(2)}`
      };
    }

    // Check customer restriction (if coupon is customer-specific)
    if (discount.discountCustomers && discount.discountCustomers.length > 0) {
      if (!customerId) {
        return { valid: false, message: 'This coupon requires a customer to be selected' };
      }
      const isCustomerAllowed = discount.discountCustomers.some(
        dc => Number(dc.customer_id) === Number(customerId)
      );
      if (!isCustomerAllowed) {
        return { valid: false, message: 'This coupon is not valid for the selected customer' };
      }
    }

    // Check product restriction (if coupon is product-specific)
    let eligibleSubtotal = subtotal;
    if (discount.discountProducts && discount.discountProducts.length > 0) {
      const allowedProductIds = discount.discountProducts.map(dp => Number(dp.product_id));
      const eligibleItems = items.filter(item => allowedProductIds.includes(Number(item.product_id)));

      if (eligibleItems.length === 0) {
        return { valid: false, message: 'This coupon is not valid for the items in your cart' };
      }

      // Calculate discount only on eligible products
      eligibleSubtotal = eligibleItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    }

    // Check product quantity requirement
    if (discount.product_quantity) {
      const totalQuantity = items.reduce((sum, item) => sum + item.quantity, 0);
      if (totalQuantity < discount.product_quantity) {
        return {
          valid: false,
          message: `This coupon requires at least ${discount.product_quantity} items in cart`
        };
      }
    }

    // Calculate discount amount
    let discountAmount = 0;
    const discountValue = Number(discount.value) || 0;

    if (discount.type_option === 'percentage') {
      discountAmount = (eligibleSubtotal * discountValue) / 100;
    } else {
      // Fixed amount
      discountAmount = discountValue;
    }

    // Ensure discount doesn't exceed eligible subtotal
    discountAmount = Math.min(discountAmount, eligibleSubtotal);

    return {
      valid: true,
      discount: {
        id: Number(discount.id),
        code: discount.code,
        title: discount.title,
        type_option: discount.type_option,
        value: discountValue,
        discount_amount: Math.round(discountAmount * 100) / 100,
      },
      message: 'Coupon applied successfully',
    };
  }

  /**
   * Increment coupon usage count after successful order
   * @param {number} discountId - Discount ID
   */
  async incrementUsage(discountId) {
    try {
      await prisma.discount.update({
        where: { id: BigInt(discountId) },
        data: {
          total_used: {
            increment: 1,
          },
        },
      });
    } catch (e) {
      console.warn('Failed to increment coupon usage:', e.message);
    }
  }

  /**
   * Calculate manual discount
   * @param {string} type - 'percentage' or 'amount'
   * @param {number} value - Discount value
   * @param {number} subtotal - Cart subtotal
   * @returns {Object} - Calculated discount info
   */
  calculateManualDiscount(type, value, subtotal) {
    let discountAmount = 0;

    if (type === 'percentage') {
      discountAmount = (subtotal * value) / 100;
    } else {
      discountAmount = value;
    }

    // Ensure discount doesn't exceed subtotal
    discountAmount = Math.min(discountAmount, subtotal);

    return {
      type,
      value,
      discount_amount: Math.round(discountAmount * 100) / 100,
    };
  }
}

module.exports = new DiscountsService();
