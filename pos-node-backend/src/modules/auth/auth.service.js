const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const config = require('../../config');
const { prisma } = require('../../config/database');

class AuthService {
  /**
   * Login user with username/email and password
   */
  async login(username, password, deviceName) {
    // Find user by email or username
    const user = await prisma.user.findFirst({
      where: {
        OR: [{ email: username }, { username: username }],
        deleted_at: null,
      },
      include: {
        roleUsers: {
          include: {
            role: true,
          },
        },
      },
    });

    if (!user) {
      throw new Error('Invalid credentials');
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password || '');
    if (!isValidPassword) {
      throw new Error('Invalid credentials');
    }

    // Check POS permission
    const permissions = user.permissions ? JSON.parse(user.permissions) : {};
    const hasPosPermission =
      user.super_user ||
      permissions['pos.index'] ||
      permissions['pos-pro'] ||
      user.roleUsers.some((ru) => {
        const rolePerms = ru.role.permissions ? JSON.parse(ru.role.permissions) : {};
        return rolePerms['pos.index'] || rolePerms['pos-pro'];
      });

    if (!hasPosPermission) {
      throw new Error('You do not have permission to access POS');
    }

    // Generate JWT token
    const jwtToken = jwt.sign(
      {
        userId: Number(user.id),
        email: user.email,
        deviceName,
      },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn }
    );

    // Generate token hash for database (compatible with Laravel Sanctum)
    const tokenHash = crypto.createHash('sha256').update(jwtToken).digest('hex');

    // Save token to database
    await prisma.personalAccessToken.create({
      data: {
        tokenable_type: 'Botble\\ACL\\Models\\User',
        tokenable_id: user.id,
        name: deviceName || 'POS Token',
        token: tokenHash,
        abilities: JSON.stringify(['*']),
        created_at: new Date(),
        updated_at: new Date(),
      },
    });

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { last_login: new Date() },
    });

    return {
      token: jwtToken,
      user: this.formatUser(user),
    };
  }

  /**
   * Get current user
   */
  async getCurrentUser(userId) {
    const user = await prisma.user.findUnique({
      where: { id: BigInt(userId) },
    });

    if (!user || user.deleted_at) {
      throw new Error('User not found');
    }

    return this.formatUser(user);
  }

  /**
   * Logout user - invalidate token
   */
  async logout(token) {
    try {
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

      await prisma.personalAccessToken.deleteMany({
        where: { token: tokenHash },
      });

      return true;
    } catch (error) {
      console.error('Logout error:', error);
      return true; // Still return success
    }
  }

  /**
   * Verify user password (for lock screen unlock)
   */
  async verifyPassword(userId, password) {
    const user = await prisma.user.findUnique({
      where: { id: BigInt(userId) },
    });

    if (!user || user.deleted_at) {
      throw new Error('User not found');
    }

    const isValidPassword = await bcrypt.compare(password, user.password || '');
    if (!isValidPassword) {
      throw new Error('Invalid password');
    }

    return true;
  }

  /**
   * Format user for API response
   */
  formatUser(user) {
    return {
      id: Number(user.id),
      name: `${user.first_name || ''} ${user.last_name || ''}`.trim() || user.username || 'User',
      email: user.email,
      store_id: user.store_id ? Number(user.store_id) : null,
      store_name: null, // Could be fetched from mp_stores if needed
    };
  }
}

module.exports = new AuthService();
