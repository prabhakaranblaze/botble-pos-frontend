const sessionsService = require('./sessions.service');
const { z } = require('zod');

const openSessionSchema = z.object({
  cash_register_id: z.number().int().positive().optional(),
  opening_cash: z.number().min(0),
  opening_denominations: z.record(z.number()).optional(),
  opening_notes: z.string().optional(),
});

const closeSessionSchema = z.object({
  session_id: z.number().int().positive(),
  closing_cash: z.number().min(0),
  actual_cash: z.number().min(0).optional(),
  closing_denominations: z.record(z.number()).optional(),
  closing_notes: z.string().optional(),
});

class SessionsController {
  /**
   * GET /cash-registers
   */
  async getCashRegisters(req, res, next) {
    try {
      const storeId = req.user?.storeId || null;
      const registers = await sessionsService.getCashRegisters(storeId);

      res.json({
        error: false,
        data: { cash_registers: registers },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /sessions/active
   */
  async getActiveSession(req, res, next) {
    try {
      const userId = req.user.id;
      const session = await sessionsService.getActiveSession(userId);

      if (!session) {
        return res.status(404).json({
          error: true,
          message: 'No active session',
        });
      }

      res.json({
        error: false,
        data: { session },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /sessions/open
   */
  async openSession(req, res, next) {
    try {
      const { opening_cash, opening_notes } = openSessionSchema.parse(req.body);
      const userId = req.user.id;

      const session = await sessionsService.openSession(userId, opening_cash, opening_notes);

      res.json({
        error: false,
        data: { session },
      });
    } catch (error) {
      if (error.message === 'You already have an open session') {
        return res.status(400).json({
          error: true,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * POST /sessions/close
   */
  async closeSession(req, res, next) {
    try {
      const { session_id, closing_cash, actual_cash, closing_notes } = closeSessionSchema.parse(req.body);
      const userId = req.user.id;

      const session = await sessionsService.closeSession(
        session_id,
        userId,
        closing_cash,
        actual_cash ?? closing_cash,
        closing_notes
      );

      res.json({
        error: false,
        data: { session },
      });
    } catch (error) {
      if (error.message === 'Session not found or already closed') {
        return res.status(404).json({
          error: true,
          message: error.message,
        });
      }
      next(error);
    }
  }
}

module.exports = new SessionsController();
