const { prisma } = require('../../config/database');
const bcrypt = require('bcryptjs');

class CustomersService {
  /**
   * Search customers
   */
  async searchCustomers(keyword) {
    if (!keyword || keyword.length < 2) {
      return [];
    }

    const customers = await prisma.customer.findMany({
      where: {
        deleted_at: null,
        status: 'activated',
        OR: [
          { name: { contains: keyword } },
          { email: { contains: keyword } },
          { phone: { contains: keyword } },
        ],
      },
      take: 20,
      orderBy: { name: 'asc' },
    });

    return customers.map((c) => this.formatCustomer(c));
  }

  /**
   * Create new customer
   */
  async createCustomer(data) {
    // Check if email already exists
    if (data.email) {
      const existing = await prisma.customer.findFirst({
        where: { email: data.email, deleted_at: null },
      });

      if (existing) {
        throw new Error('Email already exists');
      }
    }

    // Generate random password
    const password = await bcrypt.hash(Math.random().toString(36), 10);

    const customer = await prisma.customer.create({
      data: {
        name: data.name,
        email: data.email || null,
        phone: data.phone || null,
        password,
        status: 'activated',
        confirmed_at: new Date(),
        created_at: new Date(),
        updated_at: new Date(),
      },
    });

    return this.formatCustomer(customer);
  }

  /**
   * Get customer by ID
   */
  async getCustomerById(id) {
    const customer = await prisma.customer.findFirst({
      where: {
        id: BigInt(id),
        deleted_at: null,
      },
    });

    return customer ? this.formatCustomer(customer) : null;
  }

  /**
   * Format customer for API response
   */
  formatCustomer(customer) {
    return {
      id: Number(customer.id),
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      address: null, // ec_customers doesn't have address field directly
    };
  }
}

module.exports = new CustomersService();
