const { prisma } = require('../../config/database');

class SessionsService {
  /**
   * Get all cash registers
   */
  async getCashRegisters(storeId = null) {
    const where = {
      is_active: true,
      deleted_at: null,
    };

    if (storeId) {
      where.store_id = BigInt(storeId);
    }

    const registers = await prisma.posCashRegister.findMany({
      where,
      orderBy: { name: 'asc' },
    });

    return registers.map((r) => ({
      id: Number(r.id),
      name: r.name,
      code: r.code,
      store_id: Number(r.store_id),
      description: r.description,
      is_active: r.is_active,
      initial_float: Number(r.initial_float),
    }));
  }

  /**
   * Get active session for user (using pos_registers table)
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

    return this.formatSession(session);
  }

  /**
   * Open a new session
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
      throw new Error('You already have an open session');
    }

    const session = await prisma.posRegister.create({
      data: {
        user_id: BigInt(userId),
        cash_start: openingCash,
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

    return this.formatSession(session);
  }

  /**
   * Close session
   */
  async closeSession(sessionId, userId, closingCash, actualCash, notes = null) {
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

    // Calculate difference
    const difference = actualCash - closingCash;

    const updatedSession = await prisma.posRegister.update({
      where: { id: BigInt(sessionId) },
      data: {
        cash_end: closingCash,
        actual_cash: actualCash,
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

    return this.formatSession(updatedSession);
  }

  /**
   * Format session for API response
   */
  formatSession(session) {
    const userName = session.user
      ? `${session.user.first_name || ''} ${session.user.last_name || ''}`.trim() || session.user.username
      : 'User';

    return {
      id: Number(session.id),
      user_id: Number(session.user_id),
      user_name: userName,
      cash_register_id: null, // pos_registers doesn't have this
      cash_register_name: 'Default Register',
      status: session.status,
      opened_at: session.opened_at?.toISOString(),
      closed_at: session.closed_at?.toISOString(),
      opening_cash: Number(session.cash_start),
      closing_cash: session.cash_end ? Number(session.cash_end) : null,
      actual_cash: session.actual_cash ? Number(session.actual_cash) : null,
      difference: Number(session.difference),
      opening_notes: session.notes,
      closing_notes: session.notes,
    };
  }
}

module.exports = new SessionsService();
