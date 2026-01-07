const customersService = require('./customers.service');
const { z } = require('zod');

const createCustomerSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email().optional().nullable(),
  phone: z.string().optional().nullable(),
  address: z.string().optional().nullable(),
});

class CustomersController {
  /**
   * GET /customers/search
   */
  async searchCustomers(req, res, next) {
    try {
      const keyword = req.query.keyword || '';
      const customers = await customersService.searchCustomers(keyword);

      res.json({
        error: false,
        data: { customers },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /customers
   */
  async createCustomer(req, res, next) {
    try {
      const data = createCustomerSchema.parse(req.body);
      const customer = await customersService.createCustomer(data);

      res.json({
        error: false,
        data: { customer },
      });
    } catch (error) {
      if (error.message === 'Email already exists') {
        return res.status(400).json({
          error: true,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * GET /customers/:id
   */
  async getCustomer(req, res, next) {
    try {
      const customer = await customersService.getCustomerById(req.params.id);

      if (!customer) {
        return res.status(404).json({
          error: true,
          message: 'Customer not found',
        });
      }

      res.json({
        error: false,
        data: { customer },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CustomersController();
