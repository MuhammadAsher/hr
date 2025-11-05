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

const registerValidation = [
  // Organization fields
  body('organizationName').trim().isLength({ min: 2, max: 255 }).withMessage('Organization name must be 2-255 characters'),
  body('organizationEmail').isEmail().normalizeEmail().withMessage('Valid organization email is required'),
  body('organizationPhone').optional().isMobilePhone().withMessage('Valid phone number required'),
  body('organizationAddress').optional().trim().isLength({ max: 500 }).withMessage('Address too long'),
  body('industry').trim().notEmpty().withMessage('Industry is required'),
  // Admin user fields
  body('adminName').trim().isLength({ min: 2, max: 255 }).withMessage('Admin name must be 2-255 characters'),
  body('adminEmail').isEmail().normalizeEmail().withMessage('Valid admin email is required'),
  body('adminPassword').isLength({ min: 6 }).withMessage('Admin password must be at least 6 characters'),
  body('confirmPassword').custom((value, { req }) => {
    if (value !== req.body.adminPassword) {
      throw new Error('Password confirmation does not match password');
    }
    return true;
  }),
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

/**
 * @swagger
 * /api/v1/auth/register:
 *   post:
 *     summary: Register new organization
 *     description: Register a new organization with admin account (public endpoint)
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [organizationName, organizationEmail, industry, adminName, adminEmail, adminPassword, confirmPassword]
 *             properties:
 *               organizationName:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 255
 *                 example: "Tech Solutions Inc."
 *               organizationEmail:
 *                 type: string
 *                 format: email
 *                 example: "contact@techsolutions.com"
 *               organizationPhone:
 *                 type: string
 *                 example: "+1-555-0101"
 *               organizationAddress:
 *                 type: string
 *                 example: "123 Tech Street, City, State"
 *               industry:
 *                 type: string
 *                 example: "Technology"
 *               adminName:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 255
 *                 example: "John Doe"
 *               adminEmail:
 *                 type: string
 *                 format: email
 *                 example: "admin@techsolutions.com"
 *               adminPassword:
 *                 type: string
 *                 minLength: 6
 *                 example: "admin123"
 *               confirmPassword:
 *                 type: string
 *                 example: "admin123"
 *     responses:
 *       201:
 *         description: Organization registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LoginResponse'
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       409:
 *         description: Organization or email already exists
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
// Register new organization endpoint (public)
router.post('/register', registerValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid input data',
        details: errors.array(),
        code: 400,
      });
    }

    const {
      organizationName,
      organizationEmail,
      organizationPhone,
      organizationAddress,
      industry,
      adminName,
      adminEmail,
      adminPassword,
    } = req.body;

    // Check if organization email already exists
    const existingOrg = await Organization.findOne({ where: { email: organizationEmail } });
    if (existingOrg) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'Organization with this email already exists',
        code: 409,
      });
    }

    // Check if admin email already exists
    const existingUser = await User.findOne({ where: { email: adminEmail } });
    if (existingUser) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'User with this email already exists',
        code: 409,
      });
    }

    // Create organization with Free plan
    const organization = await Organization.create({
      name: organizationName,
      email: organizationEmail,
      phone: organizationPhone || null,
      address: organizationAddress || null,
      industry: industry,
      subscription_plan: 'Free',
      employee_limit: Organization.getSubscriptionLimits().Free.employees,
    });

    // Create admin user for the organization
    const adminUser = await User.create({
      organization_id: organization.id,
      email: adminEmail,
      password_hash: adminPassword, // Will be hashed by beforeCreate hook
      name: adminName,
      role: 'admin',
      email_verified: false, // Email verification can be added later
      is_active: true,
    });

    // Update organization with admin ID
    await organization.update({ admin_id: adminUser.id });

    // Generate tokens for immediate login
    const token = generateToken(adminUser);
    const refreshToken = generateRefreshToken(adminUser);

    // Return success response with tokens (user is automatically logged in)
    res.status(201).json({
      status: true,
      message: 'Organization registered successfully',
      data: {
        token,
        refreshToken,
        user: {
          id: adminUser.id,
          email: adminUser.email,
          name: adminUser.name,
          role: adminUser.role,
          organizationId: adminUser.organization_id,
          isSuperAdmin: adminUser.is_super_admin,
          organization: {
            id: organization.id,
            name: organization.name,
          },
        },
        expiresIn: 86400, // 24 hours in seconds
      },
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to register organization',
      code: 500,
    });
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
