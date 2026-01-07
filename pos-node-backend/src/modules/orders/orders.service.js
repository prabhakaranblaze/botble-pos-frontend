const { prisma } = require('../../config/database');
const cartService = require('../cart/cart.service');
const discountsService = require('../discounts/discounts.service');
const crypto = require('crypto');

class OrdersService {
  /**
   * Generate order code (Laravel style: #SF-10000XXX)
   * Gets next ID from database to create sequential codes
   */
  async generateOrderCode() {
    // Get the highest order ID to generate next code
    const lastOrder = await prisma.order.findFirst({
      orderBy: { id: 'desc' },
      select: { id: true },
    });
    const nextId = lastOrder ? Number(lastOrder.id) + 1 : 1;
    // Laravel format: #SF-10000XXX (10 million + order id)
    return `#SF-${10000000 + nextId}`;
  }

  /**
   * Generate unique token
   */
  generateToken() {
    return crypto.randomBytes(16).toString('hex');
  }

  /**
   * Generate charge ID for payment (10 random uppercase chars)
   */
  generateChargeId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    let result = '';
    for (let i = 0; i < 10; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /**
   * Create order from cart (checkout) - uses server-side cart
   * @deprecated Use checkoutDirect instead
   */
  async checkout(userId, paymentDetails = null) {
    const cart = cartService.getCartData(userId);

    if (!cart.items || cart.items.length === 0) {
      throw new Error('Cart is empty');
    }

    const paymentMethod = cart.payment_method || 'cash';

    // Create order
    const order = await prisma.order.create({
      data: {
        code: this.generateOrderCode(),
        user_id: cart.customer_id ? BigInt(cart.customer_id) : null,
        status: 'completed', // POS orders are completed immediately
        amount: cart.total,
        tax_amount: cart.tax,
        shipping_amount: cart.shipping_amount,
        discount_amount: cart.discount,
        sub_total: cart.subtotal,
        is_confirmed: true,
        is_finished: true,
        completed_at: new Date(),
        token: this.generateToken(),
        description: `POS Order - ${paymentMethod.toUpperCase()}`,
        created_at: new Date(),
        updated_at: new Date(),
      },
    });

    // Create order products
    for (const item of cart.items) {
      await prisma.orderProduct.create({
        data: {
          order_id: order.id,
          product_id: BigInt(item.id),
          product_name: item.name,
          product_image: item.image,
          qty: item.quantity,
          price: item.price,
          tax_amount: (item.price * item.quantity * 0.15), // 15% tax
          options: item.attributes ? JSON.stringify(item.attributes) : null,
          created_at: new Date(),
          updated_at: new Date(),
        },
      });

      // Update product stock
      await prisma.product.update({
        where: { id: BigInt(item.id) },
        data: {
          quantity: {
            decrement: item.quantity,
          },
        },
      });
    }

    // Clear cart
    cartService.clearCart(userId);

    // Return formatted order
    return this.formatOrder(order, cart.items, paymentMethod, paymentDetails);
  }

  /**
   * Generate invoice code (INV-YYYYMMDD-XXXXX)
   */
  async generateInvoiceCode() {
    const date = new Date();
    const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');
    const lastInvoice = await prisma.invoice.findFirst({
      orderBy: { id: 'desc' },
      select: { id: true },
    });
    const nextId = lastInvoice ? Number(lastInvoice.id) + 1 : 1;
    return `INV-${dateStr}-${String(nextId).padStart(5, '0')}`;
  }

  /**
   * Create order directly from client cart items
   * No server-side cart sync needed - items sent directly from Flutter
   * Creates payment record, order, and invoice (Laravel style)
   */
  async checkoutDirect(userId, {
    items,
    paymentMethod = 'pos_cash',
    paymentDetails = null,
    customerId = null,
    // New discount/shipping parameters
    discountId = null,          // Coupon discount ID (for usage tracking)
    couponCode = null,          // Coupon code
    discountAmount = 0,         // Calculated discount amount
    discountDescription = null, // Description (for manual discount)
    shippingAmount = 0,         // Shipping amount
    deliveryType = 'pickup',    // 'pickup' or 'ship'
    taxAmount = null,           // Client-calculated tax (if provided)
    customerName = null,        // For invoice
    customerEmail = null,
    customerPhone = null,
    // Address info
    addressId = null,           // Customer address ID (for shipping)
    customerAddress = null,     // Full formatted address for invoice
  }) {
    console.log('========== CHECKOUT DIRECT ==========');
    console.log('checkoutDirect received params:');
    console.log('  - userId:', userId);
    console.log('  - items count:', items?.length);
    console.log('  - paymentMethod:', paymentMethod);
    console.log('  - taxAmount (from client):', taxAmount, '(type:', typeof taxAmount, ')');
    console.log('  - discountAmount:', discountAmount, '(type:', typeof discountAmount, ')');
    console.log('  - shippingAmount:', shippingAmount, '(type:', typeof shippingAmount, ')');
    console.log('  - couponCode:', couponCode);
    console.log('  - customerId:', customerId);

    if (!items || items.length === 0) {
      throw new Error('Cart is empty');
    }

    // Calculate totals from items
    const subtotal = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    console.log('  - subtotal (calculated):', subtotal);

    // Calculate tax: use client-provided tax or calculate per-item tax
    let tax = 0;
    if (taxAmount !== null && taxAmount !== undefined) {
      tax = taxAmount;
      console.log('  - Using client-provided tax:', tax);
    } else {
      // Calculate from item tax rates (fallback to 0 if not provided)
      tax = items.reduce((sum, item) => {
        const itemTaxRate = item.tax_rate || 0;
        return sum + (item.price * item.quantity * itemTaxRate / 100);
      }, 0);
      console.log('  - Tax calculated from item rates:', tax);
    }

    // Calculate total: subtotal + tax - discount + shipping
    const total = subtotal + tax - discountAmount + shippingAmount;
    console.log('  - total (calculated):', total);
    console.log('  - Final values for order: tax=', tax, ', discount=', discountAmount, ', shipping=', shippingAmount);

    // Map payment method to Laravel's format (pos_cash, pos_card)
    const paymentChannel = paymentMethod === 'card' ? 'pos_card' :
                           paymentMethod === 'pos_card' ? 'pos_card' : 'pos_cash';

    // Create payment record first (Laravel style)
    const payment = await prisma.payment.create({
      data: {
        currency: 'SCR',
        user_id: BigInt(userId),
        charge_id: this.generateChargeId(),
        payment_channel: paymentChannel,
        description: `POS Payment - ${paymentChannel.toUpperCase()}`,
        amount: total,
        payment_fee: 0,
        status: 'completed',
        payment_type: 'confirm',
        customer_id: customerId ? BigInt(customerId) : null,
        customer_type: customerId ? 'Botble\\Ecommerce\\Models\\Customer' : null,
        created_at: new Date(),
        updated_at: new Date(),
      },
    });

    // Generate order code (async - sequential like Laravel)
    const orderCode = await this.generateOrderCode();

    // Create order with payment_id linked
    console.log('Creating order with data:');
    console.log('  - tax_amount:', tax);
    console.log('  - discount_amount:', discountAmount);
    console.log('  - shipping_amount:', shippingAmount);
    console.log('  - sub_total:', subtotal);
    console.log('  - amount (total):', total);

    const order = await prisma.order.create({
      data: {
        code: orderCode,
        user_id: customerId ? BigInt(customerId) : null,
        status: 'completed', // POS orders are completed immediately
        amount: total,
        tax_amount: tax,
        shipping_amount: shippingAmount,
        discount_amount: discountAmount,
        coupon_code: couponCode,
        discount_description: discountDescription,
        sub_total: subtotal,
        is_confirmed: true,
        is_finished: true,
        completed_at: new Date(),
        token: this.generateToken(),
        payment_id: payment.id, // Link to payment record
        description: `POS Order - ${paymentChannel.toUpperCase()}`,
        created_at: new Date(),
        updated_at: new Date(),
      },
    });

    console.log('Order created:', order.id, order.code);
    console.log('  - Saved tax_amount:', order.tax_amount);
    console.log('  - Saved discount_amount:', order.discount_amount);
    console.log('  - Saved shipping_amount:', order.shipping_amount);

    // Update payment with order_id
    await prisma.payment.update({
      where: { id: payment.id },
      data: { order_id: order.id },
    });

    // Create order products
    for (const item of items) {
      const itemTaxRate = item.tax_rate || 0;
      const itemTaxAmount = item.price * item.quantity * itemTaxRate / 100;

      await prisma.orderProduct.create({
        data: {
          order_id: order.id,
          product_id: BigInt(item.product_id),
          product_name: item.name,
          product_image: item.image || null,
          qty: item.quantity,
          price: item.price,
          tax_amount: itemTaxAmount,
          options: null,
          created_at: new Date(),
          updated_at: new Date(),
        },
      });

      // Update product stock (optional - skip if product doesn't exist)
      try {
        await prisma.product.update({
          where: { id: BigInt(item.product_id) },
          data: {
            quantity: {
              decrement: item.quantity,
            },
          },
        });
      } catch (e) {
        // Product might not exist - that's okay for POS
        console.log(`Note: Could not update stock for product ${item.product_id}`);
      }
    }

    // Increment coupon usage if coupon was used
    if (discountId) {
      await discountsService.incrementUsage(discountId);
    }

    // Create invoice
    const invoice = await this.createInvoice({
      orderId: order.id,
      orderCode,
      customerId,
      customerName,
      customerEmail,
      customerPhone,
      customerAddress,
      deliveryType,
      subtotal,
      taxAmount: tax,
      shippingAmount,
      discountAmount,
      couponCode,
      discountDescription,
      total,
      paymentId: payment.id,
      items,
    });

    // Format items for response
    const formattedItems = items.map(item => ({
      id: item.product_id,
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      sku: item.sku || null,
      tax_rate: item.tax_rate || 0,
    }));

    return {
      id: Number(order.id),
      code: order.code,
      amount: total,
      sub_total: subtotal,
      tax_amount: tax,
      discount_amount: discountAmount,
      shipping_amount: shippingAmount,
      coupon_code: couponCode,
      discount_description: discountDescription,
      payment_method: paymentChannel,
      payment_id: Number(payment.id),
      invoice_id: Number(invoice.id),
      invoice_code: invoice.code,
      status: order.status,
      created_at: order.created_at.toISOString(),
      payment_details: paymentDetails,
      items: formattedItems,
    };
  }

  /**
   * Create invoice for an order
   * Uses Laravel-compatible defaults for guest customers
   */
  async createInvoice({
    orderId,
    orderCode,
    customerId,
    customerName,
    customerEmail,
    customerPhone,
    customerAddress,
    deliveryType = 'pickup',
    subtotal,
    taxAmount,
    shippingAmount,
    discountAmount,
    couponCode,
    discountDescription,
    total,
    paymentId,
    items,
  }) {
    const invoiceCode = await this.generateInvoiceCode();

    // Use Laravel-compatible defaults for guest customers
    const finalCustomerName = customerName || 'Guest';
    const finalCustomerEmail = customerEmail || 'guest@example.com';
    const finalCustomerPhone = customerPhone || 'N/A';
    // Address: use provided address for shipping, or 'Pickup at Store' for pickup
    const finalCustomerAddress = deliveryType === 'ship' && customerAddress
      ? customerAddress
      : 'Pickup at Store';

    // Create invoice
    const invoice = await prisma.invoice.create({
      data: {
        reference_type: 'Botble\\Ecommerce\\Models\\Order',
        reference_id: orderId,
        code: invoiceCode,
        customer_name: finalCustomerName,
        customer_email: finalCustomerEmail,
        customer_phone: finalCustomerPhone,
        customer_address: finalCustomerAddress,
        sub_total: subtotal,
        tax_amount: taxAmount,
        shipping_amount: shippingAmount,
        discount_amount: discountAmount,
        coupon_code: couponCode,
        discount_description: discountDescription,
        amount: total,
        payment_id: paymentId,
        status: 'completed',
        paid_at: new Date(),
        created_at: new Date(),
        updated_at: new Date(),
      },
    });

    // Create invoice items with Laravel-compatible options JSON
    for (const item of items) {
      const itemTaxRate = item.tax_rate || 0;
      const itemSubtotal = item.price * item.quantity;
      const itemTax = itemSubtotal * itemTaxRate / 100;
      const itemTotal = itemSubtotal + itemTax;

      // Build options JSON matching Laravel format
      // attributes: display string like "Size: Large • Color: Red" or "Default"
      const itemOptions = {
        image: item.image || '',
        attributes: item.options || '',
        taxRate: itemTaxRate,
        taxClasses: itemTaxRate > 0 ? { 'VAT': itemTaxRate } : {},
        options: [],
        extras: [],
        sku: item.sku || '',
        weight: item.weight || 0,
      };

      await prisma.invoiceItem.create({
        data: {
          invoice_id: invoice.id,
          reference_type: 'Botble\\Ecommerce\\Models\\Product',
          reference_id: BigInt(item.product_id),
          name: item.name,
          image: item.image || null,
          qty: item.quantity,
          sub_total: itemSubtotal,
          tax_amount: itemTax,
          discount_amount: 0,
          amount: itemTotal,
          options: JSON.stringify(itemOptions),
          created_at: new Date(),
          updated_at: new Date(),
        },
      });
    }

    return invoice;
  }

  /**
   * Get recent orders for reprinting
   * Returns last N orders from today's session
   */
  async getRecentOrders({ limit = 20, search = null }) {
    const where = {
      status: 'completed',
    };

    // Search by order code if provided
    if (search) {
      where.code = { contains: search };
    }

    const orders = await prisma.order.findMany({
      where,
      orderBy: { created_at: 'desc' },
      take: limit,
      include: {
        orderProducts: true,
        payment: true,
      },
    });

    return orders.map(order => this.formatOrderFromDb(order));
  }

  /**
   * Get order by ID
   */
  async getOrderById(orderId) {
    const order = await prisma.order.findUnique({
      where: { id: BigInt(orderId) },
      include: {
        orderProducts: true,
        customer: true,
      },
    });

    if (!order) {
      return null;
    }

    return this.formatOrderFromDb(order);
  }

  /**
   * Get receipt HTML for order
   */
  async getReceipt(orderId) {
    const order = await this.getOrderById(orderId);

    if (!order) {
      throw new Error('Order not found');
    }

    const receiptHtml = this.generateReceiptHtml(order);
    return receiptHtml;
  }

  /**
   * Format order for API response (from checkout)
   */
  formatOrder(order, items, paymentMethod, paymentDetails) {
    return {
      id: Number(order.id),
      code: order.code,
      amount: Number(order.amount),
      payment_method: paymentMethod,
      status: order.status,
      created_at: order.created_at.toISOString(),
      payment_details: paymentDetails,
      items: items.map((item) => ({
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        sku: item.sku,
      })),
    };
  }

  /**
   * Format order from database
   */
  formatOrderFromDb(order) {
    // Get payment method from payment relation if available
    const paymentMethod = order.payment?.payment_channel || 'pos_cash';

    return {
      id: Number(order.id),
      code: order.code,
      amount: Number(order.amount),
      tax_amount: Number(order.tax_amount || 0),
      discount_amount: Number(order.discount_amount || 0),
      shipping_amount: Number(order.shipping_amount || 0),
      coupon_code: order.coupon_code,
      discount_description: order.discount_description,
      sub_total: Number(order.sub_total),
      payment_method: paymentMethod,
      status: order.status,
      created_at: order.created_at?.toISOString(),
      customer: order.customer
        ? {
            id: Number(order.customer.id),
            name: order.customer.name,
            email: order.customer.email,
            phone: order.customer.phone,
          }
        : null,
      items: order.orderProducts.map((op) => ({
        id: op.product_id ? Number(op.product_id) : null,
        name: op.product_name,
        price: Number(op.price),
        quantity: op.qty,
        image: op.product_image,
      })),
    };
  }

  /**
   * Generate receipt HTML
   */
  generateReceiptHtml(order) {
    const itemsHtml = order.items
      .map(
        (item) => `
        <tr>
          <td>${item.name}</td>
          <td style="text-align:center">${item.quantity}</td>
          <td style="text-align:right">SCR ${item.price.toFixed(2)}</td>
          <td style="text-align:right">SCR ${(item.price * item.quantity).toFixed(2)}</td>
        </tr>
      `
      )
      .join('');

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Receipt - ${order.code}</title>
        <style>
          body { font-family: 'Courier New', monospace; font-size: 12px; max-width: 300px; margin: 0 auto; }
          .header { text-align: center; margin-bottom: 10px; }
          .header h1 { font-size: 16px; margin: 0; }
          .divider { border-top: 1px dashed #000; margin: 10px 0; }
          table { width: 100%; border-collapse: collapse; }
          th, td { padding: 4px 2px; }
          th { text-align: left; border-bottom: 1px solid #000; }
          .totals td { padding-top: 8px; }
          .total-row { font-weight: bold; font-size: 14px; }
          .footer { text-align: center; margin-top: 20px; font-size: 10px; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>StampSmart POS</h1>
          <p>Receipt</p>
        </div>

        <div class="divider"></div>

        <p><strong>Order:</strong> ${order.code}</p>
        <p><strong>Date:</strong> ${new Date(order.created_at).toLocaleString()}</p>
        ${order.customer ? `<p><strong>Customer:</strong> ${order.customer.name}</p>` : ''}

        <div class="divider"></div>

        <table>
          <thead>
            <tr>
              <th>Item</th>
              <th style="text-align:center">Qty</th>
              <th style="text-align:right">Price</th>
              <th style="text-align:right">Total</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
        </table>

        <div class="divider"></div>

        <table class="totals">
          <tr>
            <td>Subtotal:</td>
            <td style="text-align:right">SCR ${order.sub_total.toFixed(2)}</td>
          </tr>
          <tr>
            <td>Tax:</td>
            <td style="text-align:right">SCR ${order.tax_amount.toFixed(2)}</td>
          </tr>
          ${order.discount_amount > 0 ? `
          <tr>
            <td>Discount:</td>
            <td style="text-align:right">-SCR ${order.discount_amount.toFixed(2)}</td>
          </tr>
          ` : ''}
          ${order.shipping_amount > 0 ? `
          <tr>
            <td>Shipping:</td>
            <td style="text-align:right">SCR ${order.shipping_amount.toFixed(2)}</td>
          </tr>
          ` : ''}
          <tr class="total-row">
            <td>TOTAL:</td>
            <td style="text-align:right">SCR ${order.amount.toFixed(2)}</td>
          </tr>
        </table>

        <div class="divider"></div>

        <div class="footer">
          <p>Thank you for your purchase!</p>
          <p>Please come again</p>
        </div>
      </body>
      </html>
    `;
  }
}

module.exports = new OrdersService();
