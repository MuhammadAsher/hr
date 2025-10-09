const express = require('express');
const { body, validationResult } = require('express-validator');
const { User, Organization } = require('../models');
const {
  generateToken,
  generateRefreshToken,
  verifyRefreshToken,
  authenticateToken,
} = require('../middleware/auth');

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Authentication
 *   description: User authentication and authorization endpoints
 */

// Validation rules
const loginValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('role').isIn(['admin', 'employee']).withMessage('Role must be admin or employee'),
];

const refreshTokenValidation = [
  body('refreshToken').notEmpty().withMessage('Refresh token is required'),
];

/**
 * @swagger
 * /api/v1/auth/login:
 *   post:
 *     summary: User login
 *     description: Authenticate user and return JWT tokens
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LoginRequest'
 *           examples:
 *             admin:
 *               summary: Admin login
 *               value:
 *                 email: admin@hr.com
 *                 password: admin123
 *                 role: admin
 *             employee:
 *               summary: Employee login
 *               value:
 *                 email: employee@hr.com
 *                 password: employee123
 *                 role: employee
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LoginResponse'
 *       400:
 *         description: Invalid input data
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       401:
 *         description: Invalid credentials
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Login endpoint
router.post('/login', loginValidation, async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.validationError(errors.array(), 'Invalid input data');
    }

    const { email, password, role } = req.body;

    // Find user by email
    let user;
    
    // Check for super admin first
    if (email === process.env.SUPER_ADMIN_EMAIL) {
      user = await User.findOne({
        where: {
          email,
          is_super_admin: true,
          is_active: true,
        },
      });
    } else {
      // Find regular user
      user = await User.findOne({
        where: {
          email,
          role,
          is_active: true,
        },
        include: [
          {
            model: Organization,
            as: 'organization',
            attributes: ['id', 'name', 'is_active'],
          },
        ],
      });
    }

    if (!user) {
      return res.unauthorized('Invalid credentials');
    }

    // Validate password
    const isValidPassword = await user.validatePassword(password);
    if (!isValidPassword) {
      return res.unauthorized('Invalid credentials');
    }

    // Check if organization is active (except for super admin)
    if (!user.is_super_admin && user.organization && !user.organization.is_active) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Organization is inactive',
        code: 403,
      });
    }

    // Update last login
    await user.updateLastLogin();

    // Generate tokens
    const token = generateToken(user);
    const refreshToken = generateRefreshToken(user);

    // Return success response
    res.status(200).json({
      status: true,
      message: 'Login successful',
      data: {
        token,
        refreshToken,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          organizationId: user.organization_id,
          isSuperAdmin: user.is_super_admin,
          organization: user.organization ? {
            id: user.organization.id,
            name: user.organization.name,
          } : null,
        },
        expiresIn: 86400, // 24 hours in seconds
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.error('Login failed', 500);
  }
});

// Refresh token endpoint
router.post('/refresh', refreshTokenValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid input data',
        code: 400,
        details: errors.array(),
      });
    }

    const { refreshToken } = req.body;

    // Verify refresh token
    const decoded = verifyRefreshToken(refreshToken);
    
    // Find user
    const user = await User.findByPk(decoded.userId, {
      include: [
        {
          model: Organization,
          as: 'organization',
          attributes: ['id', 'name', 'is_active'],
        },
      ],
    });

    if (!user || !user.is_active) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'User not found or inactive',
        code: 401,
      });
    }

    // Generate new tokens
    const newToken = generateToken(user);
    const newRefreshToken = generateRefreshToken(user);

    res.status(200).json({
      message: 'Token refreshed successfully',
      token: newToken,
      refreshToken: newRefreshToken,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        organizationId: user.organization_id,
        isSuperAdmin: user.is_super_admin,
      },
      expiresIn: 86400,
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid refresh token',
      code: 401,
    });
  }
});

/**
 * @swagger
 * /api/v1/auth/logout:
 *   post:
 *     summary: User logout
 *     description: Logout user and invalidate session
 *     tags: [Authentication]
 *     responses:
 *       200:
 *         description: Logout successful
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         timestamp:
 *                           type: string
 *                           format: date-time
 *                           description: Logout timestamp
 *       401:
 *         description: Unauthorized - Invalid or missing token
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Logout endpoint
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    // In a production app, you might want to blacklist the token
    // For now, we'll just return success
    res.success({
      timestamp: new Date().toISOString(),
    }, 'Logout successful');
  } catch (error) {
    console.error('Logout error:', error);
    res.error('Logout failed', 500);
  }
});

// Get current user profile
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      include: [
        {
          model: Organization,
          as: 'organization',
          attributes: ['id', 'name', 'subscription_plan', 'is_active'],
        },
      ],
    });

    res.status(200).json({
      data: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        organizationId: user.organization_id,
        isSuperAdmin: user.is_super_admin,
        lastLogin: user.last_login,
        organization: user.organization,
      },
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get user profile',
      code: 500,
    });
  }
});

module.exports = router;
