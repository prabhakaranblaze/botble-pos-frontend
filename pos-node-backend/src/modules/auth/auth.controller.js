const authService = require('./auth.service');
const { z } = require('zod');

const loginSchema = z.object({
  username: z.string().min(1, 'Username is required'),
  password: z.string().min(1, 'Password is required'),
  device_name: z.string().optional().default('POS Terminal'),
});

class AuthController {
  /**
   * POST /auth/login
   */
  async login(req, res, next) {
    try {
      const { username, password, device_name } = loginSchema.parse(req.body);

      const result = await authService.login(username, password, device_name);

      res.json({
        error: false,
        message: 'Login successful',
        data: result,
      });
    } catch (error) {
      if (error.message === 'Invalid credentials') {
        return res.status(401).json({
          error: true,
          message: 'Invalid credentials',
        });
      }
      if (error.message.includes('permission')) {
        return res.status(403).json({
          error: true,
          message: error.message,
        });
      }
      next(error);
    }
  }

  /**
   * GET /auth/me
   */
  async me(req, res, next) {
    try {
      const user = await authService.getCurrentUser(req.user.id);

      res.json({
        error: false,
        data: { user },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /auth/logout
   */
  async logout(req, res, next) {
    try {
      const token = req.headers.authorization?.split(' ')[1];
      await authService.logout(token);

      res.json({
        error: false,
        message: 'Logged out successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /auth/verify-password
   * Verify password for lock screen unlock
   */
  async verifyPassword(req, res, next) {
    try {
      const { password } = req.body;

      if (!password) {
        return res.status(400).json({
          error: true,
          message: 'Password is required',
        });
      }

      await authService.verifyPassword(req.user.id, password);

      res.json({
        error: false,
        message: 'Password verified',
      });
    } catch (error) {
      if (error.message === 'Invalid password') {
        return res.status(401).json({
          error: true,
          message: 'Invalid password',
        });
      }
      next(error);
    }
  }
}

module.exports = new AuthController();
