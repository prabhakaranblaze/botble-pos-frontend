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
      include: {
        addresses: {
          where: { deleted_at: null },
          orderBy: [{ is_default: 'desc' }, { created_at: 'desc' }],
        },
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
      include: {
        addresses: {
          where: { deleted_at: null },
          orderBy: [{ is_default: 'desc' }, { created_at: 'desc' }],
        },
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
      addresses: customer.addresses
        ? customer.addresses.map((a) => this.formatAddress(a))
        : [],
    };
  }

  // ========== ADDRESS OPERATIONS ==========

  /**
   * Get all addresses for a customer
   */
  async getCustomerAddresses(customerId) {
    const addresses = await prisma.customerAddress.findMany({
      where: {
        customer_id: BigInt(customerId),
        deleted_at: null,
      },
      orderBy: [
        { is_default: 'desc' }, // Default address first
        { created_at: 'desc' },
      ],
    });

    return addresses.map((a) => this.formatAddress(a));
  }

  /**
   * Create new address for a customer
   */
  async createCustomerAddress(customerId, data) {
    // If this is the first address or marked as default, update other addresses
    if (data.is_default) {
      await prisma.customerAddress.updateMany({
        where: {
          customer_id: BigInt(customerId),
          deleted_at: null,
        },
        data: { is_default: 0 },
      });
    }

    // Check if customer has any addresses
    const existingCount = await prisma.customerAddress.count({
      where: {
        customer_id: BigInt(customerId),
        deleted_at: null,
      },
    });

    const address = await prisma.customerAddress.create({
      data: {
        customer_id: BigInt(customerId),
        name: data.name,
        email: data.email || null,
        phone: data.phone || null,
        address: data.address || null,
        city: data.city || null,
        state: data.state || null,
        country: data.country || 'SC', // Default to Seychelles
        zip_code: data.zip_code || null,
        is_default: existingCount === 0 ? 1 : (data.is_default ? 1 : 0), // First address is default
        created_at: new Date(),
        updated_at: new Date(),
      },
    });

    return this.formatAddress(address);
  }

  /**
   * Get address by ID
   */
  async getAddressById(addressId) {
    const address = await prisma.customerAddress.findFirst({
      where: {
        id: BigInt(addressId),
        deleted_at: null,
      },
    });

    return address ? this.formatAddress(address) : null;
  }

  /**
   * Format address for API response
   */
  formatAddress(address) {
    return {
      id: Number(address.id),
      name: address.name,
      email: address.email,
      phone: address.phone,
      address: address.address,
      city: address.city,
      state: address.state,
      country: address.country,
      zip_code: address.zip_code,
      is_default: address.is_default === 1,
      // Formatted display string
      full_address: [
        address.address,
        address.city,
        address.zip_code,
      ].filter(Boolean).join(', '),
    };
  }
}

module.exports = new CustomersService();
