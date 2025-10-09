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
 *   name: Payslips
 *   description: Employee payroll and payslip management
 */

// Apply authentication to all routes
router.use(authenticateToken);

// Validation rules
const generatePayslipValidation = [
  body('employeeId').isUUID().withMessage('Valid employee ID required'),
  body('payPeriodStart').isISO8601().withMessage('Valid pay period start date required'),
  body('payPeriodEnd').isISO8601().withMessage('Valid pay period end date required'),
  body('basicSalary').isNumeric().isFloat({ min: 0 }).withMessage('Valid basic salary required'),
  body('allowances').optional().isNumeric().isFloat({ min: 0 }).withMessage('Allowances must be a positive number'),
  body('deductions').optional().isNumeric().isFloat({ min: 0 }).withMessage('Deductions must be a positive number'),
  body('overtime').optional().isNumeric().isFloat({ min: 0 }).withMessage('Overtime must be a positive number'),
];

const updatePayslipValidation = [
  param('payslipId').isUUID().withMessage('Valid payslip ID required'),
  body('basicSalary').optional().isNumeric().isFloat({ min: 0 }).withMessage('Valid basic salary required'),
  body('allowances').optional().isNumeric().isFloat({ min: 0 }).withMessage('Allowances must be a positive number'),
  body('deductions').optional().isNumeric().isFloat({ min: 0 }).withMessage('Deductions must be a positive number'),
  body('overtime').optional().isNumeric().isFloat({ min: 0 }).withMessage('Overtime must be a positive number'),
];

/**
 * @swagger
 * /api/v1/payslips:
 *   get:
 *     summary: Get all payslips
 *     description: Retrieve a paginated list of payslips with filtering options
 *     tags: [Payslips]
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
 *         name: employeeId
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by employee ID
 *       - in: query
 *         name: payPeriod
 *         schema:
 *           type: string
 *           pattern: '^[0-9]{4}-[0-9]{2}$'
 *           example: '2024-01'
 *         description: Filter by pay period (YYYY-MM format)
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [draft, processed, paid, all]
 *           default: all
 *         description: Filter by payslip status
 *       - in: query
 *         name: year
 *         schema:
 *           type: integer
 *           minimum: 2020
 *           maximum: 2030
 *         description: Filter by year
 *       - in: query
 *         name: month
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 12
 *         description: Filter by month (1-12)
 *     responses:
 *       200:
 *         description: Payslips retrieved successfully
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
 *                         payslips:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/Payslip'
 *                         pagination:
 *                           $ref: '#/components/schemas/Pagination'
 *                         filters:
 *                           type: object
 *                           properties:
 *                             employeeId:
 *                               type: string
 *                               description: Applied employee filter
 *                             payPeriod:
 *                               type: string
 *                               description: Applied pay period filter
 *                             status:
 *                               type: string
 *                               description: Applied status filter
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
// Get all payslips
router.get('/', async (req, res) => {
  try {
    // TODO: Implement payslip listing with filtering by employee, pay period, status
    res.success({
      payslips: [],
      pagination: {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 10,
        total: 0,
        totalPages: 0
      },
      filters: {
        employeeId: req.query.employeeId || 'all',
        payPeriod: req.query.payPeriod || 'current',
        status: req.query.status || 'all'
      }
    }, 'Payslips listing - Ready for implementation');
  } catch (error) {
    console.error('Get payslips error:', error);
    res.error('Failed to fetch payslips', 500);
  }
});

/**
 * @swagger
 * /api/v1/payslips/{payslipId}:
 *   get:
 *     summary: Get payslip by ID
 *     description: Retrieve a specific payslip by its ID
 *     tags: [Payslips]
 *     parameters:
 *       - in: path
 *         name: payslipId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Payslip ID
 *     responses:
 *       200:
 *         description: Payslip retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Payslip'
 *       400:
 *         description: Invalid payslip ID
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
 *         description: Payslip not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Get payslip by ID
router.get('/:payslipId', param('payslipId').isUUID(), async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid payslip ID',
        details: errors.array(),
        code: 400,
      });
    }

    // TODO: Implement get payslip by ID with employee details
    res.status(200).json({
      data: {
        id: req.params.payslipId,
        employeeId: 'temp-employee-id',
        payPeriodStart: new Date().toISOString(),
        payPeriodEnd: new Date().toISOString(),
        basicSalary: 0,
        allowances: 0,
        deductions: 0,
        overtime: 0,
        grossPay: 0,
        netPay: 0,
        status: 'draft'
      },
      message: 'Payslip details - Ready for implementation'
    });
  } catch (error) {
    console.error('Get payslip error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch payslip',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/payslips:
 *   post:
 *     summary: Generate new payslip
 *     description: Generate a new payslip for an employee (Admin only)
 *     tags: [Payslips]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [employeeId, payPeriodStart, payPeriodEnd, basicSalary]
 *             properties:
 *               employeeId:
 *                 type: string
 *                 format: uuid
 *                 description: Employee ID
 *                 example: "123e4567-e89b-12d3-a456-426614174000"
 *               payPeriodStart:
 *                 type: string
 *                 format: date
 *                 description: Pay period start date
 *                 example: "2024-01-01"
 *               payPeriodEnd:
 *                 type: string
 *                 format: date
 *                 description: Pay period end date
 *                 example: "2024-01-31"
 *               basicSalary:
 *                 type: number
 *                 minimum: 0
 *                 description: Basic salary amount
 *                 example: 5000
 *               allowances:
 *                 type: number
 *                 minimum: 0
 *                 description: Total allowances
 *                 example: 1000
 *               deductions:
 *                 type: number
 *                 minimum: 0
 *                 description: Total deductions
 *                 example: 500
 *               overtime:
 *                 type: number
 *                 minimum: 0
 *                 description: Overtime amount
 *                 example: 200
 *     responses:
 *       201:
 *         description: Payslip generated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Payslip'
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
 *         description: Conflict - Payslip already exists for this period
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Generate new payslip (Admin only)
router.post('/', requireAdmin, generatePayslipValidation, async (req, res) => {
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

    // TODO: Implement payslip generation with calculations
    const basicSalary = parseFloat(req.body.basicSalary);
    const allowances = parseFloat(req.body.allowances) || 0;
    const deductions = parseFloat(req.body.deductions) || 0;
    const overtime = parseFloat(req.body.overtime) || 0;

    const grossPay = basicSalary + allowances + overtime;
    const netPay = grossPay - deductions;

    res.status(201).json({
      message: 'Payslip generated successfully - Ready for implementation',
      data: {
        id: 'temp-id',
        employeeId: req.body.employeeId,
        payPeriodStart: req.body.payPeriodStart,
        payPeriodEnd: req.body.payPeriodEnd,
        basicSalary,
        allowances,
        deductions,
        overtime,
        grossPay,
        netPay,
        status: 'draft',
        generatedBy: req.user.userId
      }
    });
  } catch (error) {
    console.error('Generate payslip error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to generate payslip',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/payslips/{payslipId}:
 *   put:
 *     summary: Update payslip
 *     description: Update a payslip (Admin only, only if status is draft)
 *     tags: [Payslips]
 *     parameters:
 *       - in: path
 *         name: payslipId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Payslip ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               basicSalary:
 *                 type: number
 *                 minimum: 0
 *                 description: Basic salary amount
 *               allowances:
 *                 type: number
 *                 minimum: 0
 *                 description: Total allowances
 *               deductions:
 *                 type: number
 *                 minimum: 0
 *                 description: Total deductions
 *               overtime:
 *                 type: number
 *                 minimum: 0
 *                 description: Overtime amount
 *     responses:
 *       200:
 *         description: Payslip updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Payslip'
 *       400:
 *         description: Validation error or payslip not in draft status
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
 *         description: Payslip not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Update payslip (Admin only, only if draft)
router.put('/:payslipId', requireAdmin, updatePayslipValidation, async (req, res) => {
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

    // TODO: Implement payslip update (check if draft status)
    res.status(200).json({
      message: 'Payslip updated successfully - Ready for implementation',
      data: {
        id: req.params.payslipId,
        ...req.body
      }
    });
  } catch (error) {
    console.error('Update payslip error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update payslip',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/payslips/{payslipId}/finalize:
 *   post:
 *     summary: Finalize payslip
 *     description: Finalize a payslip, changing status from draft to processed (Admin only)
 *     tags: [Payslips]
 *     parameters:
 *       - in: path
 *         name: payslipId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Payslip ID
 *     responses:
 *       200:
 *         description: Payslip finalized successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Payslip'
 *       400:
 *         description: Invalid payslip ID or payslip not in draft status
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
 *         description: Payslip not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Finalize payslip (Admin only)
router.post('/:payslipId/finalize', requireAdmin, param('payslipId').isUUID(), async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid payslip ID',
        details: errors.array(),
        code: 400,
      });
    }

    // TODO: Implement payslip finalization (change status to finalized)
    res.status(200).json({
      message: 'Payslip finalized successfully - Ready for implementation',
      data: {
        id: req.params.payslipId,
        status: 'finalized',
        finalizedBy: req.user.userId,
        finalizedAt: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Finalize payslip error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to finalize payslip',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/payslips/{payslipId}:
 *   delete:
 *     summary: Delete payslip
 *     description: Delete a payslip by its ID (Admin only, only if status is draft)
 *     tags: [Payslips]
 *     parameters:
 *       - in: path
 *         name: payslipId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Payslip ID
 *     responses:
 *       200:
 *         description: Payslip deleted successfully
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
 *                         deletedPayslipId:
 *                           type: string
 *                           format: uuid
 *                           description: ID of the deleted payslip
 *       400:
 *         description: Invalid payslip ID or payslip not in draft status
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
 *         description: Payslip not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Delete payslip (Admin only, only if draft)
router.delete('/:payslipId', requireAdmin, param('payslipId').isUUID(), async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid payslip ID',
        details: errors.array(),
        code: 400,
      });
    }

    // TODO: Implement payslip deletion (check if draft status)
    res.status(200).json({
      message: 'Payslip deleted successfully - Ready for implementation'
    });
  } catch (error) {
    console.error('Delete payslip error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to delete payslip',
      code: 500,
    });
  }
});

module.exports = router;
