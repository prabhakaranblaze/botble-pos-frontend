const { prisma } = require('../../config/database');

class ReportsService {
  /**
   * Get orders report with date filtering
   * Returns orders list and summary statistics for the logged-in user
   */
  async getOrdersReport(userId, { fromDate, toDate }) {
    console.log('📊 REPORTS SERVICE: getOrdersReport');
    console.log('  - userId:', userId);
    console.log('  - fromDate:', fromDate);
    console.log('  - toDate:', toDate);

    // Build where clause for date filtering
    const where = {
      status: 'completed',
    };

    if (fromDate || toDate) {
      where.created_at = {};
      if (fromDate) {
        where.created_at.gte = new Date(fromDate);
      }
      if (toDate) {
        // Add 1 day to include the entire end date
        const endDate = new Date(toDate);
        endDate.setDate(endDate.getDate() + 1);
        where.created_at.lt = endDate;
      }
    }

    // Get orders with payment info
    const orders = await prisma.order.findMany({
      where,
      orderBy: { created_at: 'desc' },
      include: {
        payment: true,
        customer: true,
        orderProducts: true,
      },
    });

    // Calculate summary
    const totalOrders = orders.length;
    const totalRevenue = orders.reduce((sum, order) => sum + Number(order.amount || 0), 0);
    const averageOrder = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    // Format orders for response
    const formattedOrders = orders.map(order => ({
      id: Number(order.id),
      code: order.code,
      created_at: order.created_at?.toISOString(),
      customer_name: order.customer?.name || null,
      items_count: order.orderProducts?.length || 0,
      sub_total: Number(order.sub_total || 0),
      tax_amount: Number(order.tax_amount || 0),
      discount_amount: Number(order.discount_amount || 0),
      amount: Number(order.amount || 0),
      payment_method: order.payment?.payment_channel || 'pos_cash',
      status: order.status,
    }));

    console.log('✅ REPORTS SERVICE: Found', totalOrders, 'orders');

    return {
      orders: formattedOrders,
      summary: {
        total_orders: totalOrders,
        total_revenue: totalRevenue,
        average_order: averageOrder,
      },
    };
  }

  /**
   * Get products sold report with date filtering and sorting
   * Aggregates product sales data across orders
   */
  async getProductsReport(userId, { fromDate, toDate, sortBy = 'quantity', sortOrder = 'desc' }) {
    console.log('📊 REPORTS SERVICE: getProductsReport');
    console.log('  - userId:', userId);
    console.log('  - fromDate:', fromDate);
    console.log('  - toDate:', toDate);
    console.log('  - sortBy:', sortBy);
    console.log('  - sortOrder:', sortOrder);

    // Build where clause for date filtering on orders
    const orderWhere = {
      status: 'completed',
    };

    if (fromDate || toDate) {
      orderWhere.created_at = {};
      if (fromDate) {
        orderWhere.created_at.gte = new Date(fromDate);
      }
      if (toDate) {
        const endDate = new Date(toDate);
        endDate.setDate(endDate.getDate() + 1);
        orderWhere.created_at.lt = endDate;
      }
    }

    // Get all order products from completed orders within date range
    const orderProducts = await prisma.orderProduct.findMany({
      where: {
        order: orderWhere,
      },
      include: {
        product: {
          select: {
            id: true,
            name: true,
            sku: true,
          },
        },
        order: {
          select: {
            created_at: true,
          },
        },
      },
    });

    // Aggregate by product (using product_id + product_name as key for variations)
    const productMap = new Map();

    for (const op of orderProducts) {
      // Create unique key combining product_id and name (for variations)
      const key = `${op.product_id || 'unknown'}_${op.product_name}`;

      if (!productMap.has(key)) {
        productMap.set(key, {
          product_id: op.product_id ? Number(op.product_id) : null,
          name: op.product_name,
          sku: op.product?.sku || null,
          variation: this.extractVariation(op.options),
          quantity: 0,
          revenue: 0,
        });
      }

      const product = productMap.get(key);
      product.quantity += op.qty;
      product.revenue += Number(op.price) * op.qty;
    }

    // Convert to array
    let products = Array.from(productMap.values());

    // Sort products
    products.sort((a, b) => {
      let comparison = 0;
      switch (sortBy) {
        case 'quantity':
          comparison = a.quantity - b.quantity;
          break;
        case 'revenue':
          comparison = a.revenue - b.revenue;
          break;
        case 'name':
          comparison = a.name.localeCompare(b.name);
          break;
        default:
          comparison = a.quantity - b.quantity;
      }
      return sortOrder === 'desc' ? -comparison : comparison;
    });

    // Calculate summary
    const totalProducts = products.length;
    const totalQuantity = products.reduce((sum, p) => sum + p.quantity, 0);
    const totalRevenue = products.reduce((sum, p) => sum + p.revenue, 0);

    console.log('✅ REPORTS SERVICE: Found', totalProducts, 'products sold');

    return {
      products,
      summary: {
        total_products: totalProducts,
        total_quantity: totalQuantity,
        total_revenue: totalRevenue,
      },
    };
  }

  /**
   * Extract variation info from options JSON
   */
  extractVariation(optionsJson) {
    if (!optionsJson) return null;

    try {
      const options = typeof optionsJson === 'string' ? JSON.parse(optionsJson) : optionsJson;
      // Options might contain attributes like { "Size": "Large", "Color": "Red" }
      if (options.attributes && typeof options.attributes === 'string') {
        return options.attributes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

module.exports = new ReportsService();
