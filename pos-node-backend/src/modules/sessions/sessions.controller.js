const sessionsService = require('./sessions.service');
const { z } = require('zod');

const openSessionSchema = z.object({
  opening_cash: z.number().min(0),
  opening_notes: z.string().optional(),
});

const closeSessionSchema = z.object({
  session_id: z.number().int().positive(),
  closing_cash: z.number().min(0), // This is the actual counted cash
  closing_notes: z.string().optional(),
});

class SessionsController {
  /**
   * GET /sessions/active
   * Get current user's active session
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
   * Open a new register/session with opening cash
   */
  async openSession(req, res, next) {
    try {
      const { opening_cash, opening_notes } = openSessionSchema.parse(req.body);
      const userId = req.user.id;

      const session = await sessionsService.openSession(userId, opening_cash, opening_notes);

      res.json({
        error: false,
        message: 'Register opened successfully',
        data: { session },
      });
    } catch (error) {
      if (error.message?.includes('already have an open')) {
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
   * Close the register/session with closing cash count
   */
  async closeSession(req, res, next) {
    try {
      const { session_id, closing_cash, closing_notes } = closeSessionSchema.parse(req.body);
      const userId = req.user.id;

      const session = await sessionsService.closeSession(
        session_id,
        userId,
        closing_cash, // Actual counted cash
        closing_notes
      );

      res.json({
        error: false,
        message: 'Register closed successfully',
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

  /**
   * GET /sessions/history
   * Get session history for current user
   */
  async getSessionHistory(req, res, next) {
    try {
      const userId = req.user.id;
      const limit = parseInt(req.query.limit) || 10;

      const sessions = await sessionsService.getSessionHistory(userId, limit);

      res.json({
        error: false,
        data: { sessions },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SessionsController();
