const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { Organization, User } = require('../models');
const {
  authenticateToken,
  requireSuperAdmin,
  requireOrganizationAccess,
} = require('../middleware/auth');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticateToken);

// Validation rules
const createOrganizationValidation = [
  body('name').trim().isLength({ min: 2, max: 255 }).withMessage('Organization name must be 2-255 characters'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('phone').optional().isMobilePhone().withMessage('Valid phone number required'),
  body('address').optional().trim().isLength({ max: 500 }).withMessage('Address too long'),
  body('industry').trim().notEmpty().withMessage('Industry is required'),
  body('subscriptionPlan').optional().isIn(['Free', 'Basic', 'Premium', 'Enterprise']).withMessage('Invalid subscription plan'),
  body('adminName').trim().isLength({ min: 2, max: 255 }).withMessage('Admin name must be 2-255 characters'),
  body('adminEmail').isEmail().normalizeEmail().withMessage('Valid admin email is required'),
  body('adminPassword').isLength({ min: 6 }).withMessage('Admin password must be at least 6 characters'),
];

const updateOrganizationValidation = [
  param('organizationId').isUUID().withMessage('Valid organization ID required'),
  body('name').optional().trim().isLength({ min: 2, max: 255 }).withMessage('Organization name must be 2-255 characters'),
  body('email').optional().isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('phone').optional().isMobilePhone().withMessage('Valid phone number required'),
  body('address').optional().trim().isLength({ max: 500 }).withMessage('Address too long'),
  body('industry').optional().trim().notEmpty().withMessage('Industry cannot be empty'),
  body('subscriptionPlan').optional().isIn(['Free', 'Basic', 'Premium', 'Enterprise']).withMessage('Invalid subscription plan'),
];

// Get all organizations (Super Admin only)
router.get('/', requireSuperAdmin, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const search = req.query.search || '';
    const offset = (page - 1) * limit;

    const whereClause = {};
    if (search) {
      const { Op } = require('sequelize');
      whereClause[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
        { industry: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows } = await Organization.findAndCountAll({
      where: whereClause,
      limit,
      offset,
      order: [['created_at', 'DESC']],
      include: [
        {
          model: User,
          as: 'users',
          attributes: ['id', 'name', 'email', 'role'],
          where: { role: 'admin' },
          required: false,
        },
      ],
    });

    res.status(200).json({
      data: rows,
      total: count,
      page,
      limit,
      totalPages: Math.ceil(count / limit),
    });
  } catch (error) {
    console.error('Get organizations error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch organizations',
      code: 500,
    });
  }
});

// Create new organization (Super Admin only)
router.post('/', requireSuperAdmin, createOrganizationValidation, async (req, res) => {
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

    const {
      name,
      email,
      phone,
      address,
      industry,
      subscriptionPlan = 'Free',
      adminName,
      adminEmail,
      adminPassword,
      taxId,
      website,
    } = req.body;

    // Check if organization email already exists
    const existingOrg = await Organization.findOne({ where: { email } });
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

    // Create organization
    const organization = await Organization.create({
      name,
      email,
      phone,
      address,
      industry,
      subscription_plan: subscriptionPlan,
      tax_id: taxId,
      website,
      employee_limit: Organization.getSubscriptionLimits()[subscriptionPlan].employees,
    });

    // Create admin user
    const adminUser = await User.create({
      organization_id: organization.id,
      email: adminEmail,
      password_hash: adminPassword,
      name: adminName,
      role: 'admin',
      email_verified: true,
    });

    // Update organization with admin ID
    await organization.update({ admin_id: adminUser.id });

    res.status(201).json({
      data: {
        ...organization.toJSON(),
        admin: {
          id: adminUser.id,
          name: adminUser.name,
          email: adminUser.email,
        },
      },
      message: 'Organization created successfully',
    });
  } catch (error) {
    console.error('Create organization error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to create organization',
      code: 500,
    });
  }
});

// Get organization by ID
router.get('/:organizationId', requireOrganizationAccess(), async (req, res) => {
  try {
    const { organizationId } = req.params;

    const organization = await Organization.findByPk(organizationId, {
      include: [
        {
          model: User,
          as: 'users',
          attributes: ['id', 'name', 'email', 'role', 'last_login'],
        },
      ],
    });

    if (!organization) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Organization not found',
        code: 404,
      });
    }

    res.status(200).json({
      data: organization,
    });
  } catch (error) {
    console.error('Get organization error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch organization',
      code: 500,
    });
  }
});

// Update organization
router.put('/:organizationId', requireOrganizationAccess(), updateOrganizationValidation, async (req, res) => {
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

    const { organizationId } = req.params;
    const updateData = req.body;

    const organization = await Organization.findByPk(organizationId);
    if (!organization) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Organization not found',
        code: 404,
      });
    }

    // Update subscription plan limits if changed
    if (updateData.subscriptionPlan && updateData.subscriptionPlan !== organization.subscription_plan) {
      const limits = Organization.getSubscriptionLimits();
      updateData.employee_limit = limits[updateData.subscriptionPlan].employees;
      updateData.subscription_plan = updateData.subscriptionPlan;
      delete updateData.subscriptionPlan;
    }

    await organization.update(updateData);

    res.status(200).json({
      data: organization,
      message: 'Organization updated successfully',
    });
  } catch (error) {
    console.error('Update organization error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update organization',
      code: 500,
    });
  }
});

// Get organization statistics
router.get('/:organizationId/stats', requireOrganizationAccess(), async (req, res) => {
  try {
    const { organizationId } = req.params;

    const organization = await Organization.findByPk(organizationId);
    if (!organization) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Organization not found',
        code: 404,
      });
    }

    // Get user counts
    const totalUsers = await User.count({
      where: { organization_id: organizationId, is_active: true },
    });

    const adminCount = await User.count({
      where: { organization_id: organizationId, role: 'admin', is_active: true },
    });

    const employeeCount = await User.count({
      where: { organization_id: organizationId, role: 'employee', is_active: true },
    });

    const usagePercentage = await organization.getUsagePercentage();

    const stats = {
      totalUsers,
      adminCount,
      employeeCount,
      employeeLimit: organization.employee_limit,
      usagePercentage,
      subscriptionPlan: organization.subscription_plan,
      isActive: organization.is_active,
      registeredDate: organization.registered_date,
    };

    res.status(200).json({
      data: stats,
    });
  } catch (error) {
    console.error('Get organization stats error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch organization statistics',
      code: 500,
    });
  }
});

module.exports = router;
