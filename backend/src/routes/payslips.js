const express = require('express');
const { body, param, validationResult } = require('express-validator');
const { Op, fn, col, where } = require('sequelize');
const { Payslip, Employee, User, sequelize } = require('../models');
const {
  authenticateToken,
  requireAdmin,
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
  body('month').isString().notEmpty().withMessage('Month is required'),
  body('year').isInt({ min: 2000, max: 2100 }).withMessage('Valid year required'),
  body('basicSalary').isFloat({ min: 0 }).withMessage('Valid basic salary required'),
  body('allowances').optional().isFloat({ min: 0 }).withMessage('Allowances must be a positive number'),
  body('deductions').optional().isFloat({ min: 0 }).withMessage('Deductions must be a positive number'),
  body('overtime').optional().isFloat({ min: 0 }).withMessage('Overtime must be a positive number'),
  body('bonus').optional().isFloat({ min: 0 }).withMessage('Bonus must be a positive number'),
  body('currency').optional().isString().isLength({ min: 3, max: 3 }).withMessage('Currency must be a 3-letter code'),
  body('allowanceBreakdown').optional().isObject().withMessage('Allowance breakdown must be an object'),
  body('deductionBreakdown').optional().isObject().withMessage('Deduction breakdown must be an object'),
];

const updatePayslipValidation = [
  param('payslipId').isUUID().withMessage('Valid payslip ID required'),
  body('basicSalary').optional().isFloat({ min: 0 }).withMessage('Valid basic salary required'),
  body('allowances').optional().isFloat({ min: 0 }).withMessage('Allowances must be a positive number'),
  body('deductions').optional().isFloat({ min: 0 }).withMessage('Deductions must be a positive number'),
  body('overtime').optional().isFloat({ min: 0 }).withMessage('Overtime must be a positive number'),
  body('bonus').optional().isFloat({ min: 0 }).withMessage('Bonus must be a positive number'),
  body('allowanceBreakdown').optional().isObject().withMessage('Allowance breakdown must be an object'),
  body('deductionBreakdown').optional().isObject().withMessage('Deduction breakdown must be an object'),
  body('notes').optional().isString().isLength({ max: 1000 }).withMessage('Notes must be less than 1000 characters'),
];

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const parseMonthInput = (value) => {
  if (value === undefined || value === null) {
    return null;
  }

  if (typeof value === 'number') {
    if (value < 1 || value > 12) return null;
    return {
      monthName: MONTHS[value - 1],
      monthNumber: value,
    };
  }

  const trimmed = value.toString().trim();

  if (/^\d+$/.test(trimmed)) {
    const num = parseInt(trimmed, 10);
    if (num >= 1 && num <= 12) {
      return {
        monthName: MONTHS[num - 1],
        monthNumber: num,
      };
    }
  }

  const normalized = trimmed.toLowerCase();
  const index = MONTHS.findIndex((m) => m.toLowerCase() === normalized);
  if (index !== -1) {
    return {
      monthName: MONTHS[index],
      monthNumber: index + 1,
    };
  }

  return null;
};

const toNumber = (value, fallback = 0) => {
  if (value === undefined || value === null || value === '') return fallback;
  const parsed = parseFloat(value);
  return Number.isNaN(parsed) ? fallback : parsed;
};

const normalizeBreakdown = (payload, fallback = {}) => {
  if (!payload || typeof payload !== 'object') {
    return { ...fallback };
  }

  return Object.entries(payload).reduce((acc, [key, val]) => {
    const numeric = toNumber(val, null);
    if (numeric !== null) {
      acc[key] = parseFloat(numeric.toFixed(2));
    }
    return acc;
  }, { ...fallback });
};

const formatCurrencyValue = (value) => parseFloat(parseFloat(value).toFixed(2));

const serializePayslip = (payslipInstance) => {
  if (!payslipInstance) {
    return null;
  }

  const payslip = payslipInstance.get({ plain: true });
  const employee = payslipInstance.employee || {};
  const generatedBy = payslipInstance.generatedBy || null;
  const finalizedBy = payslipInstance.finalizedBy || null;

  const statusLabels = {
    draft: 'Draft',
    processed: 'Processed',
    paid: 'Paid',
  };

  return {
    id: payslip.id,
    employeeId: payslip.employee_id,
    employeeName: employee.name || 'Unknown Employee',
    month: payslip.month,
    year: payslip.year,
    payPeriodStart: payslip.pay_period_start,
    payPeriodEnd: payslip.pay_period_end,
    basicSalary: formatCurrencyValue(payslip.basic_salary),
    allowances: formatCurrencyValue(payslip.allowances),
    deductions: formatCurrencyValue(payslip.deductions),
    overtime: formatCurrencyValue(payslip.overtime),
    bonus: formatCurrencyValue(payslip.bonus),
    grossSalary: formatCurrencyValue(payslip.gross_salary),
    netSalary: formatCurrencyValue(payslip.net_salary),
    allowanceBreakdown: payslip.allowance_breakdown || {},
    deductionBreakdown: payslip.deduction_breakdown || {},
    currency: payslip.currency,
    status: statusLabels[payslip.status] || payslip.status,
    generatedDate: payslip.generated_at,
    generatedBy: generatedBy ? generatedBy.name || generatedBy.email : null,
    finalizedBy: finalizedBy ? finalizedBy.name || finalizedBy.email : null,
    finalizedAt: payslip.finalized_at,
    notes: payslip.notes,
  };
};

const ensureEmployeeAccess = async (user, employeeId) => {
  if (user.is_super_admin) {
    return true;
  }

  const employee = await Employee.findByPk(employeeId, {
    attributes: ['id', 'organization_id', 'user_id'],
  });

  if (!employee) {
    return { error: { status: 404, message: 'Employee not found' } };
  }

  if (user.role === 'employee') {
    if (employee.user_id !== user.id) {
      return { error: { status: 403, message: 'You do not have access to this payslip' } };
    }
  } else if (employee.organization_id !== user.organization_id) {
    return { error: { status: 403, message: 'Employee belongs to a different organization' } };
  }

  return { employee };
};

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
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 10, 1), 100);
    const offset = (page - 1) * limit;

    const whereClause = {};

    if (!req.user.is_super_admin) {
      whereClause.organization_id = req.user.organization_id;
    }

    let employeeFilterId = req.query.employeeId || null;

    if (req.user.role === 'employee' && !req.user.is_super_admin) {
      const employeeRecord = await Employee.findOne({
        where: { user_id: req.user.id },
        attributes: ['id', 'organization_id'],
      });

      if (!employeeRecord) {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'Employee profile not found',
          code: 403,
        });
      }

      whereClause.employee_id = employeeRecord.id;
      whereClause.organization_id = employeeRecord.organization_id;
      employeeFilterId = employeeRecord.id;
    } else if (employeeFilterId) {
      whereClause.employee_id = employeeFilterId;
    }

    const statusFilter = (req.query.status || 'all').toLowerCase();
    if (['draft', 'processed', 'paid'].includes(statusFilter)) {
      whereClause.status = statusFilter;
    }

    if (req.query.year) {
      const yearValue = parseInt(req.query.year, 10);
      if (!Number.isNaN(yearValue)) {
        whereClause.year = yearValue;
      }
    }

    if (req.query.month) {
      const parsedMonth = parseMonthInput(req.query.month);
      if (!parsedMonth) {
        return res.status(400).json({
          error: 'Validation Error',
          message: 'Invalid month value',
          code: 400,
        });
      }

      whereClause[Op.and] = whereClause[Op.and] || [];
      whereClause[Op.and].push(
        where(fn('LOWER', col('month')), parsedMonth.monthName.toLowerCase()),
      );
    }

    const { count, rows } = await Payslip.findAndCountAll({
      where: whereClause,
      order: [['pay_period_start', 'DESC']],
      limit,
      offset,
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'name'],
        },
        {
          model: User,
          as: 'generatedBy',
          attributes: ['id', 'name', 'email'],
        },
        {
          model: User,
          as: 'finalizedBy',
          attributes: ['id', 'name', 'email'],
        },
      ],
    });

    res.success({
      payslips: rows.map(serializePayslip),
      pagination: {
        page,
        limit,
        total: count,
        totalPages: Math.ceil(count / limit) || 0,
      },
      filters: {
        employeeId: employeeFilterId || 'all',
        status: statusFilter,
        year: whereClause.year || req.query.year || null,
        month: req.query.month || null,
      },
    }, 'Payslips retrieved successfully');
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

    const payslip = await Payslip.findByPk(req.params.payslipId, {
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'name', 'organization_id', 'user_id'],
        },
        {
          model: User,
          as: 'generatedBy',
          attributes: ['id', 'name', 'email'],
        },
        {
          model: User,
          as: 'finalizedBy',
          attributes: ['id', 'name', 'email'],
        },
      ],
    });

    if (!payslip) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Payslip not found',
        code: 404,
      });
    }

    const access = await ensureEmployeeAccess(req.user, payslip.employee_id);
    if (access.error) {
      return res.status(access.error.status).json({
        error: access.error.status === 404 ? 'Not Found' : 'Forbidden',
        message: access.error.message,
        code: access.error.status,
      });
    }

    res.success(serializePayslip(payslip), 'Payslip retrieved successfully');
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
  const transaction = await sequelize.transaction();
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid input data',
        details: errors.array(),
        code: 400,
      });
    }

    const { employeeId, month, year } = req.body;
    const parsedMonth = parseMonthInput(month);
    if (!parsedMonth) {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid month value',
        code: 400,
      });
    }

    const { employee, error } = await ensureEmployeeAccess(req.user, employeeId);
    if (error) {
      await transaction.rollback();
      return res.status(error.status).json({
        error: error.status === 404 ? 'Not Found' : 'Forbidden',
        message: error.message,
        code: error.status,
      });
    }

    // Prevent duplicate payslips for the same period
    const existingPayslip = await Payslip.findOne({
      where: {
        employee_id: employee.id,
        organization_id: employee.organization_id,
        year: parseInt(year, 10),
        [Op.and]: [
          where(fn('LOWER', col('month')), parsedMonth.monthName.toLowerCase()),
        ],
      },
      transaction,
    });

    if (existingPayslip) {
      await transaction.rollback();
      return res.status(409).json({
        error: 'Conflict',
        message: 'Payslip already exists for this period',
        code: 409,
      });
    }

    const basicSalary = toNumber(req.body.basicSalary, 0);
    const allowances = toNumber(req.body.allowances, 0);
    const deductions = toNumber(req.body.deductions, 0);
    const overtime = toNumber(req.body.overtime, 0);
    const bonus = toNumber(req.body.bonus, 0);
    const currency = (req.body.currency || 'USD').toUpperCase();
    const allowanceBreakdown = normalizeBreakdown(req.body.allowanceBreakdown);
    const deductionBreakdown = normalizeBreakdown(req.body.deductionBreakdown);

    if (overtime > 0) {
      allowanceBreakdown.overtime = formatCurrencyValue(overtime);
    }
    if (bonus > 0) {
      allowanceBreakdown.bonus = formatCurrencyValue(bonus);
    }

    const grossSalary = basicSalary + allowances + overtime + bonus;
    const netSalary = grossSalary - deductions;

    const monthNumber = parsedMonth.monthNumber;
    const calculatedYear = parseInt(year, 10);
    const payPeriodStart = new Date(Date.UTC(calculatedYear, monthNumber - 1, 1));
    const payPeriodEnd = new Date(Date.UTC(calculatedYear, monthNumber, 0));

    const newPayslip = await Payslip.create({
      organization_id: employee.organization_id,
      employee_id: employee.id,
      month: parsedMonth.monthName,
      year: calculatedYear,
      pay_period_start: payPeriodStart,
      pay_period_end: payPeriodEnd,
      basic_salary: basicSalary,
        allowances,
      allowance_breakdown: allowanceBreakdown,
        deductions,
      deduction_breakdown: deductionBreakdown,
        overtime,
      bonus,
      gross_salary: grossSalary,
      net_salary: netSalary,
      currency,
      notes: req.body.notes || null,
      generated_by: req.user.id,
    }, { transaction });

    await transaction.commit();

    const createdPayslip = await Payslip.findByPk(newPayslip.id, {
      include: [
        { model: Employee, as: 'employee', attributes: ['id', 'name'] },
        { model: User, as: 'generatedBy', attributes: ['id', 'name', 'email'] },
      ],
    });

    res.status(201).json({
      message: 'Payslip generated successfully',
      data: serializePayslip(createdPayslip),
    });
  } catch (error) {
    await transaction.rollback();
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
  const transaction = await sequelize.transaction();
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid input data',
        details: errors.array(),
        code: 400,
      });
    }

    const payslip = await Payslip.findByPk(req.params.payslipId, {
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'organization_id'],
        },
      ],
      transaction,
    });

    if (!payslip) {
      await transaction.rollback();
      return res.status(404).json({
        error: 'Not Found',
        message: 'Payslip not found',
        code: 404,
      });
    }

    if (payslip.status !== 'draft') {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Only draft payslips can be updated',
        code: 400,
      });
    }

    const access = await ensureEmployeeAccess(req.user, payslip.employee_id);
    if (access.error) {
      await transaction.rollback();
      return res.status(access.error.status).json({
        error: access.error.status === 404 ? 'Not Found' : 'Forbidden',
        message: access.error.message,
        code: access.error.status,
      });
    }

    const updates = {};
    if (req.body.basicSalary !== undefined) updates.basic_salary = toNumber(req.body.basicSalary, payslip.basic_salary);
    if (req.body.allowances !== undefined) updates.allowances = toNumber(req.body.allowances, payslip.allowances);
    if (req.body.deductions !== undefined) updates.deductions = toNumber(req.body.deductions, payslip.deductions);
    if (req.body.overtime !== undefined) updates.overtime = toNumber(req.body.overtime, payslip.overtime);
    if (req.body.bonus !== undefined) updates.bonus = toNumber(req.body.bonus, payslip.bonus);
    if (req.body.notes !== undefined) updates.notes = req.body.notes;

    if (req.body.allowanceBreakdown) {
      updates.allowance_breakdown = normalizeBreakdown(req.body.allowanceBreakdown, payslip.allowance_breakdown);
    }

    if (req.body.deductionBreakdown) {
      updates.deduction_breakdown = normalizeBreakdown(req.body.deductionBreakdown, payslip.deduction_breakdown);
    }

    if (Object.keys(updates).length === 0) {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'No fields provided to update',
        code: 400,
      });
    }

    const basicSalary = updates.basic_salary ?? payslip.basic_salary;
    const allowances = updates.allowances ?? payslip.allowances;
    const overtime = updates.overtime ?? payslip.overtime;
    const bonus = updates.bonus ?? payslip.bonus;
    const deductions = updates.deductions ?? payslip.deductions;

    updates.gross_salary = basicSalary + allowances + overtime + bonus;
    updates.net_salary = updates.gross_salary - deductions;

    await payslip.update(updates, { transaction });
    await transaction.commit();

    const updatedPayslip = await Payslip.findByPk(payslip.id, {
      include: [
        { model: Employee, as: 'employee', attributes: ['id', 'name'] },
        { model: User, as: 'generatedBy', attributes: ['id', 'name', 'email'] },
      ],
    });

    res.success(serializePayslip(updatedPayslip), 'Payslip updated successfully');
  } catch (error) {
    await transaction.rollback();
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
  const transaction = await sequelize.transaction();
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid payslip ID',
        details: errors.array(),
        code: 400,
      });
    }

    const payslip = await Payslip.findByPk(req.params.payslipId, {
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'organization_id'],
        },
      ],
      transaction,
    });

    if (!payslip) {
      await transaction.rollback();
      return res.status(404).json({
        error: 'Not Found',
        message: 'Payslip not found',
        code: 404,
      });
    }

    const access = await ensureEmployeeAccess(req.user, payslip.employee_id);
    if (access.error) {
      await transaction.rollback();
      return res.status(access.error.status).json({
        error: access.error.status === 404 ? 'Not Found' : 'Forbidden',
        message: access.error.message,
        code: access.error.status,
      });
    }

    if (payslip.status !== 'draft') {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Only draft payslips can be finalized',
        code: 400,
      });
    }

    await payslip.update({
      status: 'processed',
      finalized_by: req.user.id,
      finalized_at: new Date(),
    }, { transaction });

    await transaction.commit();

    const updatedPayslip = await Payslip.findByPk(payslip.id, {
      include: [
        { model: Employee, as: 'employee', attributes: ['id', 'name'] },
        { model: User, as: 'generatedBy', attributes: ['id', 'name', 'email'] },
        { model: User, as: 'finalizedBy', attributes: ['id', 'name', 'email'] },
      ],
    });

    res.success(serializePayslip(updatedPayslip), 'Payslip finalized successfully');
  } catch (error) {
    await transaction.rollback();
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
  const transaction = await sequelize.transaction();
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid payslip ID',
        details: errors.array(),
        code: 400,
      });
    }

    const payslip = await Payslip.findByPk(req.params.payslipId, {
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'organization_id'],
        },
      ],
      transaction,
    });

    if (!payslip) {
      await transaction.rollback();
      return res.status(404).json({
        error: 'Not Found',
        message: 'Payslip not found',
        code: 404,
      });
    }

    const access = await ensureEmployeeAccess(req.user, payslip.employee_id);
    if (access.error) {
      await transaction.rollback();
      return res.status(access.error.status).json({
        error: access.error.status === 404 ? 'Not Found' : 'Forbidden',
        message: access.error.message,
        code: access.error.status,
      });
    }

    if (payslip.status !== 'draft') {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Only draft payslips can be deleted',
        code: 400,
      });
    }

    await payslip.destroy({ transaction });
    await transaction.commit();

    res.success({ deletedPayslipId: req.params.payslipId }, 'Payslip deleted successfully');
  } catch (error) {
    await transaction.rollback();
    console.error('Delete payslip error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to delete payslip',
      code: 500,
    });
  }
});

module.exports = router;
