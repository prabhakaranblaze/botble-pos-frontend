const customersService = require('./customers.service');
const { z } = require('zod');

const createCustomerSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email().optional().nullable(),
  phone: z.string().min(1, 'Phone is required'),
});

const createAddressSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email().optional().nullable(),
  phone: z.string().optional().nullable(),
  address: z.string().min(1, 'Address is required'),
  city: z.string().optional().nullable(),
  state: z.string().optional().nullable(),
  country: z.string().optional().nullable(),
  zip_code: z.string().optional().nullable(),
  is_default: z.boolean().optional().default(false),
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

  // ========== ADDRESS OPERATIONS ==========

  /**
   * GET /customers/:id/addresses
   */
  async getCustomerAddresses(req, res, next) {
    try {
      const customerId = req.params.id;
      const addresses = await customersService.getCustomerAddresses(customerId);

      res.json({
        error: false,
        data: { addresses },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /customers/:id/addresses
   */
  async createCustomerAddress(req, res, next) {
    try {
      const customerId = req.params.id;
      const data = createAddressSchema.parse(req.body);
      const address = await customersService.createCustomerAddress(customerId, data);

      res.json({
        error: false,
        data: { address },
      });
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({
          error: true,
          message: error.errors[0]?.message || 'Invalid request data',
        });
      }
      next(error);
    }
  }

  /**
   * GET /customers/addresses/:addressId
   */
  async getAddress(req, res, next) {
    try {
      const address = await customersService.getAddressById(req.params.addressId);

      if (!address) {
        return res.status(404).json({
          error: true,
          message: 'Address not found',
        });
      }

      res.json({
        error: false,
        data: { address },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CustomersController();
