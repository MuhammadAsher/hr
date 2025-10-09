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

/**
 * @swagger
 * tags:
 *   name: Employees
 *   description: Employee management and information
 */

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

/**
 * @swagger
 * /api/v1/employees:
 *   get:
 *     summary: Get all employees
 *     description: Retrieve a paginated list of employees with filtering options
 *     tags: [Employees]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *         description: Page number for pagination
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 20
 *         description: Number of items per page
 *       - in: query
 *         name: department
 *         schema:
 *           type: string
 *         description: Filter by department name
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, inactive, on_leave, terminated, all]
 *           default: active
 *         description: Filter by employee status
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search in employee name, email, or employee ID
 *       - in: query
 *         name: position
 *         schema:
 *           type: string
 *         description: Filter by job position
 *     responses:
 *       200:
 *         description: Employees retrieved successfully
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
 *                         employees:
 *                           type: array
 *                           items:
 *                             type: object
 *                             description: Employee object with basic information
 *                         pagination:
 *                           $ref: '#/components/schemas/Pagination'
 *                         filters:
 *                           type: object
 *                           properties:
 *                             department:
 *                               type: string
 *                               description: Applied department filter
 *                             status:
 *                               type: string
 *                               description: Applied status filter
 *       401:
 *         description: Unauthorized
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

/**
 * @swagger
 * /api/v1/employees:
 *   post:
 *     summary: Create new employee
 *     description: Create a new employee record (Admin only)
 *     tags: [Employees]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [firstName, lastName, email, employeeId, department, position, hireDate]
 *             properties:
 *               firstName:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 50
 *                 description: Employee first name
 *                 example: "John"
 *               lastName:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 50
 *                 description: Employee last name
 *                 example: "Doe"
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Employee email address
 *                 example: "john.doe@company.com"
 *               employeeId:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 20
 *                 description: Unique employee ID
 *                 example: "EMP001"
 *               department:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 100
 *                 description: Department name
 *                 example: "Engineering"
 *               position:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 100
 *                 description: Job position
 *                 example: "Software Engineer"
 *               hireDate:
 *                 type: string
 *                 format: date
 *                 description: Employee hire date
 *                 example: "2024-01-15"
 *               salary:
 *                 type: number
 *                 minimum: 0
 *                 description: Employee salary
 *                 example: 75000
 *               status:
 *                 type: string
 *                 enum: [active, inactive, on_leave, terminated]
 *                 default: active
 *                 description: Employee status
 *                 example: "active"
 *               managerId:
 *                 type: string
 *                 format: uuid
 *                 description: Manager employee ID
 *               phone:
 *                 type: string
 *                 description: Employee phone number
 *                 example: "+1-555-123-4567"
 *               address:
 *                 type: string
 *                 description: Employee address
 *                 example: "123 Main St, City, State 12345"
 *     responses:
 *       201:
 *         description: Employee created successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       description: Created employee object
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       403:
 *         description: Forbidden - Admin access required
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       409:
 *         description: Conflict - Employee ID or email already exists
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/v1/employees/{employeeId}:
 *   get:
 *     summary: Get employee by ID
 *     description: Retrieve a specific employee by their ID
 *     tags: [Employees]
 *     parameters:
 *       - in: path
 *         name: employeeId
 *         required: true
 *         schema:
 *           type: string
 *         description: Employee ID (UUID or employee number)
 *     responses:
 *       200:
 *         description: Employee retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       description: Employee object with detailed information
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Employee not found
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

/**
 * @swagger
 * /api/v1/employees/{employeeId}:
 *   put:
 *     summary: Update employee
 *     description: Update an existing employee record (Admin only)
 *     tags: [Employees]
 *     parameters:
 *       - in: path
 *         name: employeeId
 *         required: true
 *         schema:
 *           type: string
 *         description: Employee ID (UUID or employee number)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               firstName:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 50
 *                 description: Employee first name
 *               lastName:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 50
 *                 description: Employee last name
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Employee email address
 *               department:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 100
 *                 description: Department name
 *               position:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 100
 *                 description: Job position
 *               salary:
 *                 type: number
 *                 minimum: 0
 *                 description: Employee salary
 *               status:
 *                 type: string
 *                 enum: [active, inactive, on_leave, terminated]
 *                 description: Employee status
 *               managerId:
 *                 type: string
 *                 format: uuid
 *                 description: Manager employee ID
 *               phone:
 *                 type: string
 *                 description: Employee phone number
 *               address:
 *                 type: string
 *                 description: Employee address
 *     responses:
 *       200:
 *         description: Employee updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       description: Updated employee object
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       403:
 *         description: Forbidden - Admin access required
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Employee not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/v1/employees/{employeeId}:
 *   delete:
 *     summary: Delete employee
 *     description: Delete an employee record by ID (Admin only)
 *     tags: [Employees]
 *     parameters:
 *       - in: path
 *         name: employeeId
 *         required: true
 *         schema:
 *           type: string
 *         description: Employee ID (UUID or employee number)
 *     responses:
 *       200:
 *         description: Employee deleted successfully
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
 *                         deletedEmployeeId:
 *                           type: string
 *                           description: ID of the deleted employee
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       403:
 *         description: Forbidden - Admin access required
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Employee not found
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
