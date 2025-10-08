const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { Op } = require('sequelize');
const { Employee, User, Organization } = require('../models');
const {
  authenticateToken,
  requireAdmin,
  addOrganizationFilter,
} = require('../middleware/auth');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticateToken);

// Validation rules
const createEmployeeValidation = [
  body('name').trim().isLength({ min: 2, max: 255 }).withMessage('Name must be 2-255 characters'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('phone').optional().isMobilePhone().withMessage('Valid phone number required'),
  body('department').trim().notEmpty().withMessage('Department is required'),
  body('position').trim().notEmpty().withMessage('Position is required'),
  body('salary').isNumeric().isFloat({ min: 0 }).withMessage('Valid salary required'),
  body('joinDate').optional().isISO8601().withMessage('Valid join date required'),
  body('status').optional().isIn(['active', 'inactive', 'on_leave', 'terminated']).withMessage('Invalid status'),
];

const updateEmployeeValidation = [
  param('employeeId').isUUID().withMessage('Valid employee ID required'),
  body('name').optional().trim().isLength({ min: 2, max: 255 }).withMessage('Name must be 2-255 characters'),
  body('email').optional().isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('phone').optional().isMobilePhone().withMessage('Valid phone number required'),
  body('department').optional().trim().notEmpty().withMessage('Department cannot be empty'),
  body('position').optional().trim().notEmpty().withMessage('Position cannot be empty'),
  body('salary').optional().isNumeric().isFloat({ min: 0 }).withMessage('Valid salary required'),
  body('status').optional().isIn(['active', 'inactive', 'on_leave', 'terminated']).withMessage('Invalid status'),
];

// Get all employees
router.get('/', addOrganizationFilter, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const department = req.query.department;
    const status = req.query.status;
    const search = req.query.search || '';
    const offset = (page - 1) * limit;

    const whereClause = { ...req.organizationFilter };

    // Add filters
    if (department) {
      whereClause.department = department;
    }
    if (status) {
      whereClause.status = status;
    }
    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
        { employee_id: { [Op.iLike]: `%${search}%` } },
        { position: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows } = await Employee.findAndCountAll({
      where: whereClause,
      limit,
      offset,
      order: [['created_at', 'DESC']],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'email', 'last_login'],
          required: false,
        },
        {
          model: Employee,
          as: 'manager',
          attributes: ['id', 'name', 'position'],
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
    console.error('Get employees error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch employees',
      code: 500,
    });
  }
});

// Create new employee (Admin only)
router.post('/', requireAdmin, createEmployeeValidation, async (req, res) => {
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

    const organizationId = req.user.organization_id;

    // Check if organization can add more employees
    const organization = await Organization.findByPk(organizationId);
    if (!organization) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Organization not found',
        code: 404,
      });
    }

    const canAdd = await organization.canAddEmployee();
    if (!canAdd) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Employee limit reached for current subscription plan',
        code: 403,
      });
    }

    const {
      name,
      email,
      phone,
      department,
      position,
      salary,
      joinDate,
      status = 'active',
      address,
      emergencyContact,
      managerId,
    } = req.body;

    // Check if employee email already exists in organization
    const existingEmployee = await Employee.findOne({
      where: {
        email,
        organization_id: organizationId,
      },
    });

    if (existingEmployee) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'Employee with this email already exists',
        code: 409,
      });
    }

    // Generate employee ID
    const employeeId = await Employee.generateEmployeeId(organizationId);

    // Create employee
    const employee = await Employee.create({
      organization_id: organizationId,
      employee_id: employeeId,
      name,
      email,
      phone,
      department,
      position,
      salary,
      join_date: joinDate || new Date(),
      status,
      address,
      emergency_contact: emergencyContact,
      manager_id: managerId,
    });

    // Load employee with associations
    const createdEmployee = await Employee.findByPk(employee.id, {
      include: [
        {
          model: Employee,
          as: 'manager',
          attributes: ['id', 'name', 'position'],
        },
      ],
    });

    res.status(201).json({
      data: createdEmployee,
      message: 'Employee created successfully',
    });
  } catch (error) {
    console.error('Create employee error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to create employee',
      code: 500,
    });
  }
});

// Get employee by ID
router.get('/:employeeId', addOrganizationFilter, async (req, res) => {
  try {
    const { employeeId } = req.params;

    const employee = await Employee.findOne({
      where: {
        id: employeeId,
        ...req.organizationFilter,
      },
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'email', 'last_login', 'email_verified'],
        },
        {
          model: Employee,
          as: 'manager',
          attributes: ['id', 'name', 'position', 'email'],
        },
        {
          model: Employee,
          as: 'subordinates',
          attributes: ['id', 'name', 'position', 'email'],
        },
      ],
    });

    if (!employee) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Employee not found',
        code: 404,
      });
    }

    res.status(200).json({
      data: employee,
    });
  } catch (error) {
    console.error('Get employee error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch employee',
      code: 500,
    });
  }
});

// Update employee (Admin only)
router.put('/:employeeId', requireAdmin, updateEmployeeValidation, async (req, res) => {
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

    const { employeeId } = req.params;
    const updateData = req.body;

    const employee = await Employee.findOne({
      where: {
        id: employeeId,
        organization_id: req.user.organization_id,
      },
    });

    if (!employee) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Employee not found',
        code: 404,
      });
    }

    // Check if email is being changed and doesn't conflict
    if (updateData.email && updateData.email !== employee.email) {
      const existingEmployee = await Employee.findOne({
        where: {
          email: updateData.email,
          organization_id: req.user.organization_id,
          id: { [Op.ne]: employeeId },
        },
      });

      if (existingEmployee) {
        return res.status(409).json({
          error: 'Conflict',
          message: 'Employee with this email already exists',
          code: 409,
        });
      }
    }

    await employee.update(updateData);

    // Load updated employee with associations
    const updatedEmployee = await Employee.findByPk(employee.id, {
      include: [
        {
          model: Employee,
          as: 'manager',
          attributes: ['id', 'name', 'position'],
        },
      ],
    });

    res.status(200).json({
      data: updatedEmployee,
      message: 'Employee updated successfully',
    });
  } catch (error) {
    console.error('Update employee error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update employee',
      code: 500,
    });
  }
});

// Delete employee (Admin only)
router.delete('/:employeeId', requireAdmin, async (req, res) => {
  try {
    const { employeeId } = req.params;

    const employee = await Employee.findOne({
      where: {
        id: employeeId,
        organization_id: req.user.organization_id,
      },
    });

    if (!employee) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Employee not found',
        code: 404,
      });
    }

    await employee.destroy();

    res.status(204).send();
  } catch (error) {
    console.error('Delete employee error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to delete employee',
      code: 500,
    });
  }
});

module.exports = router;
