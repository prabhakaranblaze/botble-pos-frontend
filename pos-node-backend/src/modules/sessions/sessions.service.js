const { prisma } = require('../../config/database');

class SessionsService {
  /**
   * Get active session for user (using pos_registers table)
   * Laravel style - no separate cash register selection
   */
  async getActiveSession(userId) {
    const session = await prisma.posRegister.findFirst({
      where: {
        user_id: BigInt(userId),
        status: 'open',
      },
      include: {
        user: true,
      },
    });

    if (!session) {
      return null;
    }

    // Get session sales summary
    const salesSummary = await this.getSessionSalesSummary(session.id);

    return this.formatSession(session, salesSummary);
  }

  /**
   * Open a new register/session
   * Creates a new row in pos_registers with opening cash
   */
  async openSession(userId, openingCash, notes = null) {
    // Check if user already has an open session
    const existingSession = await prisma.posRegister.findFirst({
      where: {
        user_id: BigInt(userId),
        status: 'open',
      },
    });

    if (existingSession) {
      throw new Error('You already have an open register. Please close it first.');
    }

    const session = await prisma.posRegister.create({
      data: {
        user_id: BigInt(userId),
        cash_start: openingCash,
        cash_end: null,
        actual_cash: null,
        difference: 0,
        status: 'open',
        notes,
        opened_at: new Date(),
        created_at: new Date(),
        updated_at: new Date(),
      },
      include: {
        user: true,
      },
    });

    return this.formatSession(session, { cash_sales: 0, card_sales: 0, total_sales: 0, total_orders: 0 });
  }

  /**
   * Close register/session
   * Updates the pos_registers row with closing cash and calculates difference
   */
  async closeSession(sessionId, userId, closingCash, notes = null) {
    const session = await prisma.posRegister.findFirst({
      where: {
        id: BigInt(sessionId),
        user_id: BigInt(userId),
        status: 'open',
      },
    });

    if (!session) {
      throw new Error('Session not found or already closed');
    }

    // Get sales summary for this session
    const salesSummary = await this.getSessionSalesSummary(session.id);

    // Calculate expected cash: opening + cash sales
    const expectedCash = Number(session.cash_start) + salesSummary.cash_sales;

    // Difference: actual closing cash - expected cash
    // Positive = excess, Negative = short
    const difference = closingCash - expectedCash;

    const updatedSession = await prisma.posRegister.update({
      where: { id: BigInt(sessionId) },
      data: {
        cash_end: expectedCash, // Expected cash based on sales
        actual_cash: closingCash, // Actual counted cash
        difference,
        status: 'closed',
        closed_at: new Date(),
        notes: notes || session.notes,
        updated_at: new Date(),
      },
      include: {
        user: true,
      },
    });

    return this.formatSession(updatedSession, salesSummary);
  }

  /**
   * Get sales summary for a session
   * Calculates cash sales, card sales, and totals from orders
   */
  async getSessionSalesSummary(sessionId) {
    // Get orders created during this session
    const session = await prisma.posRegister.findUnique({
      where: { id: BigInt(sessionId) },
    });

    if (!session) {
      return { cash_sales: 0, card_sales: 0, total_sales: 0, total_orders: 0 };
    }

    // Find orders between session open and close (or now if still open)
    const endTime = session.closed_at || new Date();

    // Get orders for this session's user within the session time range
    const orders = await prisma.order.findMany({
      where: {
        created_at: {
          gte: session.opened_at,
          lte: endTime,
        },
        status: 'completed',
        description: {
          contains: 'POS Order',
        },
      },
      include: {
        payment: true,
      },
    });

    let cashSales = 0;
    let cardSales = 0;

    for (const order of orders) {
      const amount = Number(order.amount);
      // Check payment method from payment record
      const paymentChannel = order.payment?.payment_channel || '';
      if (paymentChannel === 'pos_card' || paymentChannel.includes('card')) {
        cardSales += amount;
      } else {
        // Default to cash (pos_cash or any other)
        cashSales += amount;
      }
    }

    return {
      cash_sales: cashSales,
      card_sales: cardSales,
      total_sales: cashSales + cardSales,
      total_orders: orders.length,
    };
  }

  /**
   * Get session history for user
   */
  async getSessionHistory(userId, limit = 10) {
    const sessions = await prisma.posRegister.findMany({
      where: {
        user_id: BigInt(userId),
      },
      orderBy: {
        created_at: 'desc',
      },
      take: limit,
      include: {
        user: true,
      },
    });

    const formattedSessions = [];
    for (const session of sessions) {
      const salesSummary = await this.getSessionSalesSummary(session.id);
      formattedSessions.push(this.formatSession(session, salesSummary));
    }

    return formattedSessions;
  }

  /**
   * Format session for API response
   */
  formatSession(session, salesSummary = null) {
    const userName = session.user
      ? `${session.user.first_name || ''} ${session.user.last_name || ''}`.trim() || session.user.username
      : 'User';

    const summary = salesSummary || { cash_sales: 0, card_sales: 0, total_sales: 0, total_orders: 0 };

    return {
      id: Number(session.id),
      user_id: Number(session.user_id),
      user_name: userName,
      status: session.status,
      opened_at: session.opened_at?.toISOString(),
      closed_at: session.closed_at?.toISOString(),
      opening_cash: Number(session.cash_start),
      closing_cash: session.cash_end ? Number(session.cash_end) : null,
      actual_cash: session.actual_cash ? Number(session.actual_cash) : null,
      expected_cash: Number(session.cash_start) + summary.cash_sales,
      difference: Number(session.difference),
      notes: session.notes,
      // Sales breakdown
      cash_sales: summary.cash_sales,
      card_sales: summary.card_sales,
      total_sales: summary.total_sales,
      total_orders: summary.total_orders,
    };
  }
}

module.exports = new SessionsService();
