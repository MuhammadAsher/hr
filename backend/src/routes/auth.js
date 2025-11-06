const express = require('express');
const { body, validationResult } = require('express-validator');
const crypto = require('crypto');
const { Op } = require('sequelize');
const { User, Organization } = require('../models');
const {
  generateToken,
  generateRefreshToken,
  verifyRefreshToken,
  authenticateToken,
  optionalAuthenticateToken,
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
    
    try {
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
        // Find regular user with optional organization association
        // Explicitly specify all User attributes to avoid column reference issues
        user = await User.findOne({
          where: {
            email,
            role,
            is_active: true,
          },
          attributes: [
            'id',
            'organization_id',
            'email',
            'password_hash',
            'name',
            'role',
            'is_super_admin',
            'is_active',
            'last_login',
            'email_verified',
            'profile_picture',
            'reset_token',
            'reset_token_expiry',
            'created_at',
            'updated_at',
          ],
          include: [
            {
              model: Organization,
              as: 'organization',
              attributes: ['id', 'name', 'is_active'],
              required: false, // Left join - don't fail if org doesn't exist
            },
          ],
        });
      }
    } catch (dbError) {
      console.error('Database error during user lookup:', dbError);
      console.error('Database error stack:', dbError.stack);
      console.error('Email:', email, 'Role:', role);
      return res.error(`Database error during login: ${dbError.message}`, 500);
    }

    if (!user) {
      console.log(`❌ User not found: email=${email}, role=${role}`);
      return res.unauthorized('Invalid credentials');
    }
    
    console.log(`✅ User found: ${user.email}, role=${user.role}, is_active=${user.is_active}`);

    // Validate password
    let isValidPassword;
    try {
      if (!user || !user.validatePassword) {
        console.error('User object is invalid or missing validatePassword method');
        return res.error('Invalid user object', 500);
      }
      isValidPassword = await user.validatePassword(password);
    } catch (passwordError) {
      console.error('Password validation error:', passwordError);
      console.error('Password validation error stack:', passwordError.stack);
      return res.error(`Password validation failed: ${passwordError.message}`, 500);
    }

    if (!isValidPassword) {
      console.log(`❌ Invalid password for user: ${user.email}`);
      return res.unauthorized('Invalid credentials');
    }
    
    console.log(`✅ Password validated successfully for user: ${user.email}`);

    // Check if organization is active (except for super admin)
    if (!user.is_super_admin && user.organization && !user.organization.is_active) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Organization is inactive',
        code: 403,
      });
    }

    // Update last login
    try {
      await user.updateLastLogin();
    } catch (updateError) {
      console.warn('Failed to update last login:', updateError);
      // Continue with login even if update fails
    }

    // Generate tokens
    let token, refreshToken;
    try {
      token = generateToken(user);
      refreshToken = generateRefreshToken(user);
    } catch (tokenError) {
      console.error('Token generation error:', tokenError);
      return res.error('Token generation failed', 500);
    }

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
    console.error('Error name:', error.name);
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    console.error('Request body:', req.body);
    res.error(`Login failed: ${error.message}`, 500);
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
// Use optional auth so logout works even if token is expired or user is deleted
router.post('/logout', optionalAuthenticateToken, async (req, res) => {
  try {
    // In a production app, you might want to blacklist the token
    // For now, we'll just return success
    // Logout should always succeed - we're clearing tokens on the client side anyway
    res.success({
      timestamp: new Date().toISOString(),
    }, 'Logout successful');
  } catch (error) {
    console.error('Logout error:', error);
    // Even if there's an error, return success since logout is primarily client-side
    res.success({
      timestamp: new Date().toISOString(),
    }, 'Logout successful');
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

// Password reset validation rules
const requestPasswordResetValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
];

const resetPasswordValidation = [
  body('token').notEmpty().withMessage('Reset token is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('confirmPassword').custom((value, { req }) => {
    if (value !== req.body.newPassword) {
      throw new Error('Password confirmation does not match password');
    }
    return true;
  }),
];

const changePasswordValidation = [
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('confirmPassword').custom((value, { req }) => {
    if (value !== req.body.newPassword) {
      throw new Error('Password confirmation does not match password');
    }
    return true;
  }),
];

/**
 * @swagger
 * /api/v1/auth/forgot-password:
 *   post:
 *     summary: Request password reset
 *     description: Send password reset token to user's email
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email]
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "user@example.com"
 *     responses:
 *       200:
 *         description: Password reset token sent successfully
 *       404:
 *         description: User not found
 */
router.post('/forgot-password', requestPasswordResetValidation, async (req, res) => {
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

    const { email } = req.body;

    // Find user by email (don't restrict by organization for password reset)
    const user = await User.findOne({
      where: { email, is_active: true },
    });

    // Don't reveal if user exists or not for security
    if (!user) {
      return res.status(200).json({
        status: true,
        message: 'If an account with that email exists, a password reset link has been sent.',
      });
    }

    // Generate reset token (32 random bytes as hex = 64 characters)
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpiry = new Date();
    resetTokenExpiry.setHours(resetTokenExpiry.getHours() + 1); // Token expires in 1 hour

    // Save reset token to user
    await user.update({
      reset_token: resetToken,
      reset_token_expiry: resetTokenExpiry,
    });

    // In production, send email with reset link
    // For now, we'll return the token in development (remove in production!)
    console.log(`Password reset token for ${email}: ${resetToken}`);

    res.status(200).json({
      status: true,
      message: 'If an account with that email exists, a password reset link has been sent.',
      // Remove this in production - only for development/testing
      data: process.env.NODE_ENV === 'development' ? { resetToken } : undefined,
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to process password reset request',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/auth/reset-password:
 *   post:
 *     summary: Reset password with token
 *     description: Reset user password using the reset token
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [token, newPassword, confirmPassword]
 *             properties:
 *               token:
 *                 type: string
 *                 example: "abc123..."
 *               newPassword:
 *                 type: string
 *                 minLength: 6
 *                 example: "newpassword123"
 *               confirmPassword:
 *                 type: string
 *                 example: "newpassword123"
 *     responses:
 *       200:
 *         description: Password reset successfully
 *       400:
 *         description: Invalid or expired token
 */
router.post('/reset-password', resetPasswordValidation, async (req, res) => {
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

    const { token, newPassword } = req.body;

    // Find user by reset token
    const user = await User.findOne({
      where: {
        reset_token: token,
        reset_token_expiry: { [Op.gt]: new Date() }, // Token not expired
      },
    });

    if (!user) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid or expired reset token',
        code: 400,
      });
    }

    // Update password (will be hashed by beforeUpdate hook)
    await user.update({
      password_hash: newPassword,
      reset_token: null,
      reset_token_expiry: null,
    });

    res.status(200).json({
      status: true,
      message: 'Password reset successfully',
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to reset password',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/auth/change-password:
 *   post:
 *     summary: Change password (authenticated)
 *     description: Change password for logged-in user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [currentPassword, newPassword, confirmPassword]
 *             properties:
 *               currentPassword:
 *                 type: string
 *                 example: "oldpassword123"
 *               newPassword:
 *                 type: string
 *                 minLength: 6
 *                 example: "newpassword123"
 *               confirmPassword:
 *                 type: string
 *                 example: "newpassword123"
 *     responses:
 *       200:
 *         description: Password changed successfully
 *       400:
 *         description: Invalid current password
 */
router.post('/change-password', authenticateToken, changePasswordValidation, async (req, res) => {
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

    const { currentPassword, newPassword } = req.body;

    // Get user from token
    const user = await User.findByPk(req.user.id);

    if (!user) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found',
        code: 404,
      });
    }

    // Verify current password
    const isValidPassword = await user.validatePassword(currentPassword);
    if (!isValidPassword) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Current password is incorrect',
        code: 400,
      });
    }

    // Update password (will be hashed by beforeUpdate hook)
    await user.update({
      password_hash: newPassword,
    });

    res.status(200).json({
      status: true,
      message: 'Password changed successfully',
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to change password',
      code: 500,
    });
  }
});

module.exports = router;
