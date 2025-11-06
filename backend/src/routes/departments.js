const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { Op } = require('sequelize');
const { Employee, User, Organization, Department } = require('../models');
const { sequelize } = require('../database/connection');
const {
  authenticateToken,
  requireAdmin,
  addOrganizationFilter,
} = require('../middleware/auth');

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Departments
 *   description: Department management endpoints
 */

// Apply authentication to all routes
router.use(authenticateToken);

// Validation rules
const createDepartmentValidation = [
  body('name').trim().isLength({ min: 2, max: 100 }).withMessage('Department name must be 2-100 characters'),
  body('description').optional().trim().isLength({ max: 500 }).withMessage('Description must be less than 500 characters'),
  body('managerId')
    .optional({ nullable: true, checkFalsy: true })
    .custom((value) => {
      if (!value || value === '' || value === null || value === undefined) {
        return true; // Allow null/empty
      }
      // Check if it's a valid UUID
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(String(value))) {
        throw new Error('Manager ID must be a valid UUID');
      }
      return true;
    })
    .withMessage('Valid manager ID (UUID) required'),
  body('budget').optional().isNumeric().isFloat({ min: 0 }).withMessage('Budget must be a positive number'),
];

const updateDepartmentValidation = [
  param('departmentId').isUUID().withMessage('Valid department ID required'),
  body('name').optional().trim().isLength({ min: 2, max: 100 }).withMessage('Department name must be 2-100 characters'),
  body('description').optional().trim().isLength({ max: 500 }).withMessage('Description must be less than 500 characters'),
  body('managerId').optional().isUUID().withMessage('Valid manager ID required'),
  body('budget').optional().isNumeric().isFloat({ min: 0 }).withMessage('Budget must be a positive number'),
];

/**
 * @swagger
 * /api/v1/departments:
 *   get:
 *     summary: Get all departments
 *     description: Retrieve a paginated list of departments for the authenticated user's organization
 *     tags: [Departments]
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
 *           default: 10
 *         description: Number of items per page
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search term for department name or description
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, inactive, all]
 *           default: active
 *         description: Filter by department status
 *     responses:
 *       200:
 *         description: Departments retrieved successfully
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
 *                         departments:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/Department'
 *                         pagination:
 *                           $ref: '#/components/schemas/Pagination'
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
// Get all departments
router.get('/', addOrganizationFilter, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const search = req.query.search || '';
    const status = req.query.status || 'active';
    const offset = (page - 1) * limit;

    const whereClause = { ...req.organizationFilter };

    // Add status filter
    if (status !== 'all') {
      whereClause.status = status;
    }

    // Add search filter (SQLite compatible - use LOWER for case-insensitive)
    if (search) {
      const searchLower = search.toLowerCase();
      whereClause[Op.or] = [
        sequelize.where(sequelize.fn('LOWER', sequelize.col('name')), { [Op.like]: `%${searchLower}%` }),
        sequelize.where(sequelize.fn('LOWER', sequelize.col('description')), { [Op.like]: `%${searchLower}%` }),
      ];
    }

    const { count, rows } = await Department.findAndCountAll({
      where: whereClause,
      limit,
      offset,
      order: [['name', 'ASC']],
      include: [
        {
          model: Employee,
          as: 'manager',
          attributes: ['id', 'name', 'email', 'position'],
          required: false,
        },
      ],
    });

    // Count employees in each department
    const departmentsWithCounts = await Promise.all(
      rows.map(async (dept) => {
        const employeeCount = await Employee.count({
          where: {
            organization_id: dept.organization_id,
            department: dept.name,
            status: 'active',
          },
        });

        const deptJson = dept.toJSON();
        return {
          ...deptJson,
          employeeCount,
          managerId: dept.manager_id,
          managerName: dept.manager?.name || null,
        };
      })
    );

    res.status(200).json({
      data: departmentsWithCounts,
      total: count,
      page,
      limit,
      totalPages: Math.ceil(count / limit),
    });
  } catch (error) {
    console.error('Get departments error:', error);
    console.error('Error name:', error.name);
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      error: 'Internal Server Error',
      message: `Failed to fetch departments: ${error.message}`,
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/departments/{departmentId}:
 *   get:
 *     summary: Get department by ID
 *     description: Retrieve a specific department by its ID
 *     tags: [Departments]
 *     parameters:
 *       - in: path
 *         name: departmentId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Department ID
 *     responses:
 *       200:
 *         description: Department retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Department'
 *       400:
 *         description: Invalid department ID
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
 *       404:
 *         description: Department not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Get department by ID
router.get('/:departmentId', addOrganizationFilter, param('departmentId').isUUID(), async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid department ID',
        details: errors.array(),
        code: 400,
      });
    }

    const { departmentId } = req.params;

    const department = await Department.findOne({
      where: {
        id: departmentId,
        ...req.organizationFilter,
      },
      include: [
        {
          model: Employee,
          as: 'manager',
          attributes: ['id', 'name', 'email', 'position'],
          required: false,
        },
      ],
    });

    if (!department) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Department not found',
        code: 404,
      });
    }

    // Count employees in this department
    const employeeCount = await Employee.count({
      where: {
        organization_id: department.organization_id,
        department: department.name,
        status: 'active',
      },
    });

    const deptJson = department.toJSON();
    res.status(200).json({
      data: {
        ...deptJson,
        employeeCount,
        managerId: department.manager_id,
        managerName: department.manager?.name || null,
      },
    });
  } catch (error) {
    console.error('Get department error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch department',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/departments:
 *   post:
 *     summary: Create new department
 *     description: Create a new department (Admin only)
 *     tags: [Departments]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, description]
 *             properties:
 *               name:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 100
 *                 description: Department name
 *                 example: "Human Resources"
 *               description:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 500
 *                 description: Department description
 *                 example: "Manages employee relations and organizational development"
 *               managerId:
 *                 type: string
 *                 format: uuid
 *                 description: Manager employee ID
 *                 example: "123e4567-e89b-12d3-a456-426614174000"
 *               budget:
 *                 type: number
 *                 minimum: 0
 *                 description: Department budget
 *                 example: 100000
 *               location:
 *                 type: string
 *                 maxLength: 200
 *                 description: Department location
 *                 example: "Building A, Floor 2"
 *     responses:
 *       201:
 *         description: Department created successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Department'
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
 */
// Create new department (Admin only)
router.post('/', requireAdmin, addOrganizationFilter, createDepartmentValidation, async (req, res) => {
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

    const organizationId = req.user.organization_id;
    const { name, description, managerId, budget, location } = req.body;

    // Check if department with same name already exists in organization
    const existingDepartment = await Department.findOne({
      where: {
        name,
        organization_id: organizationId,
      },
    });

    if (existingDepartment) {
      return res.status(409).json({
        error: 'Conflict',
        message: `A department with name "${name}" already exists in this organization`,
        code: 409,
      });
    }

    // Validate manager if provided
    if (managerId) {
      const manager = await Employee.findOne({
        where: {
          id: managerId,
          organization_id: organizationId,
          status: 'active',
        },
      });

      if (!manager) {
        return res.status(400).json({
          error: 'Validation Error',
          message: 'Manager not found or inactive in this organization',
          code: 400,
        });
      }
    }

    // Create department
    const department = await Department.create({
      organization_id: organizationId,
      name,
      description: description || null,
      manager_id: managerId || null,
      budget: budget || null,
      location: location || null,
      status: 'active',
    });

    // Load department with manager info
    const createdDepartment = await Department.findByPk(department.id, {
      include: [
        {
          model: Employee,
          as: 'manager',
          attributes: ['id', 'name', 'email', 'position'],
          required: false,
        },
      ],
    });

    // Count employees in this department (initially 0)
    const employeeCount = 0;

    const deptJson = createdDepartment.toJSON();
    res.status(201).json({
      data: {
        ...deptJson,
        employeeCount,
        managerId: createdDepartment.manager_id,
        managerName: createdDepartment.manager?.name || null,
      },
      message: 'Department created successfully',
    });
  } catch (error) {
    console.error('Create department error:', error);
    console.error('Error name:', error.name);
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    console.error('Request body:', req.body);

    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({
        error: 'Conflict',
        message: `A department with name "${req.body.name}" already exists in this organization`,
        code: 409,
      });
    }

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid input data',
        details: error.errors.map(err => ({
          field: err.path,
          message: err.message,
        })),
        code: 400,
      });
    }

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to create department',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/departments/{departmentId}:
 *   put:
 *     summary: Update department
 *     description: Update an existing department (Admin only)
 *     tags: [Departments]
 *     parameters:
 *       - in: path
 *         name: departmentId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Department ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 100
 *                 description: Department name
 *               description:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 500
 *                 description: Department description
 *               managerId:
 *                 type: string
 *                 format: uuid
 *                 description: Manager employee ID
 *               budget:
 *                 type: number
 *                 minimum: 0
 *                 description: Department budget
 *               location:
 *                 type: string
 *                 maxLength: 200
 *                 description: Department location
 *     responses:
 *       200:
 *         description: Department updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Department'
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
 *         description: Department not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Update department (Admin only)
router.put('/:departmentId', requireAdmin, updateDepartmentValidation, async (req, res) => {
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

    // TODO: Implement department update
    res.status(200).json({
      message: 'Department updated successfully - Ready for implementation',
      data: {
        id: req.params.departmentId,
        ...req.body
      }
    });
  } catch (error) {
    console.error('Update department error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update department',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/departments/{departmentId}:
 *   delete:
 *     summary: Delete department
 *     description: Delete a department by its ID (Admin only)
 *     tags: [Departments]
 *     parameters:
 *       - in: path
 *         name: departmentId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Department ID
 *     responses:
 *       200:
 *         description: Department deleted successfully
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
 *                         deletedDepartmentId:
 *                           type: string
 *                           format: uuid
 *                           description: ID of the deleted department
 *       400:
 *         description: Invalid department ID
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
 *         description: Department not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Delete department (Admin only)
router.delete('/:departmentId', requireAdmin, param('departmentId').isUUID(), async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid department ID',
        details: errors.array(),
        code: 400,
      });
    }

    // TODO: Implement department deletion (check for employees first)
    res.status(200).json({
      message: 'Department deleted successfully - Ready for implementation'
    });
  } catch (error) {
    console.error('Delete department error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to delete department',
      code: 500,
    });
  }
});

module.exports = router;
