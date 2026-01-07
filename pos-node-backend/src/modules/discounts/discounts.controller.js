const discountsService = require('./discounts.service');
const { z } = require('zod');

const validateCouponSchema = z.object({
  code: z.string().min(1, 'Coupon code is required'),
  subtotal: z.number().positive('Subtotal must be positive'),
  items: z.array(z.object({
    product_id: z.number(),
    quantity: z.number(),
    price: z.number(),
  })).optional().default([]),
  customer_id: z.number().optional().nullable(),
});

const calculateDiscountSchema = z.object({
  type: z.enum(['percentage', 'amount']),
  value: z.number().positive('Discount value must be positive'),
  subtotal: z.number().positive('Subtotal must be positive'),
});

class DiscountsController {
  /**
   * POST /discounts/validate
   * Validate and calculate coupon discount
   */
  async validateCoupon(req, res, next) {
    try {
      const data = validateCouponSchema.parse(req.body);

      const result = await discountsService.validateCoupon(
        data.code,
        data.subtotal,
        data.items,
        data.customer_id
      );

      if (!result.valid) {
        return res.status(400).json({
          error: true,
          message: result.message,
        });
      }

      res.json({
        error: false,
        data: result,
      });
    } catch (error) {
      if (error.name === 'ZodError') {
        return res.status(400).json({
          error: true,
          message: error.errors[0].message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /discounts/calculate
   * Calculate manual discount amount
   */
  async calculateDiscount(req, res, next) {
    try {
      const data = calculateDiscountSchema.parse(req.body);

      const result = discountsService.calculateManualDiscount(
        data.type,
        data.value,
        data.subtotal
      );

      res.json({
        error: false,
        data: result,
      });
    } catch (error) {
      if (error.name === 'ZodError') {
        return res.status(400).json({
          error: true,
          message: error.errors[0].message,
        });
      }
      next(error);
    }
  }
}

module.exports = new DiscountsController();
