const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { Op } = require('sequelize');
const { Employee, User, LeaveRequest, sequelize } = require('../models');
const {
  authenticateToken,
  requireAdmin,
} = require('../middleware/auth');

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Leave Requests
 *   description: Employee leave request management
 */

// Apply authentication to all routes
router.use(authenticateToken);

// Validation rules
const createLeaveRequestValidation = [
  body('leaveType').isIn(['annual', 'sick', 'personal', 'maternity', 'paternity', 'emergency']).withMessage('Invalid leave type'),
  body('startDate').isISO8601().withMessage('Valid start date required'),
  body('endDate').isISO8601().withMessage('Valid end date required'),
  body('reason').trim().isLength({ min: 10, max: 500 }).withMessage('Reason must be 10-500 characters'),
  body('halfDay').optional().isBoolean().withMessage('Half day must be boolean'),
  body('employeeId').optional().isUUID().withMessage('Valid employee ID required'),
];

const updateLeaveRequestValidation = [
  param('leaveId').isUUID().withMessage('Valid leave request ID required'),
  body('leaveType').optional().isIn(['annual', 'sick', 'personal', 'maternity', 'paternity', 'emergency']).withMessage('Invalid leave type'),
  body('startDate').optional().isISO8601().withMessage('Valid start date required'),
  body('endDate').optional().isISO8601().withMessage('Valid end date required'),
  body('reason').optional().trim().isLength({ min: 10, max: 500 }).withMessage('Reason must be 10-500 characters'),
  body('halfDay').optional().isBoolean().withMessage('Half day must be boolean'),
];

const approveRejectValidation = [
  param('leaveId').isUUID().withMessage('Valid leave request ID required'),
  body('comments').optional().trim().isLength({ max: 500 }).withMessage('Comments must be less than 500 characters'),
];

const formatLeaveRequestResponse = (requestInstance) => {
  if (!requestInstance) {
    return null;
  }
  const leave = requestInstance.toJSON();
  const employee = requestInstance.employee || {};
  const approver = requestInstance.approvedBy || null;
  const status = typeof leave.status === 'string' && leave.status.length > 0
    ? leave.status.charAt(0).toUpperCase() + leave.status.slice(1)
    : 'Pending';

  return {
    id: leave.id,
    employeeId: leave.employee_id,
    employeeName: employee.name || 'Unknown Employee',
    leaveType: leave.leave_type,
    startDate: leave.start_date instanceof Date ? leave.start_date.toISOString().split('T')[0] : leave.start_date,
    endDate: leave.end_date instanceof Date ? leave.end_date.toISOString().split('T')[0] : leave.end_date,
    reason: leave.reason,
    status,
    halfDay: leave.half_day,
    requestDate: leave.created_at instanceof Date ? leave.created_at.toISOString() : leave.created_at,
    approvedBy: approver ? approver.name : null,
    approvedDate: leave.approved_at ? (leave.approved_at instanceof Date ? leave.approved_at.toISOString() : leave.approved_at) : null,
    comments: leave.comments || null,
  };
};

/**
 * @swagger
 * /api/v1/leave-requests:
 *   get:
 *     summary: Get all leave requests
 *     description: Retrieve a paginated list of leave requests with filtering options
 *     tags: [Leave Requests]
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
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, approved, rejected, all]
 *           default: all
 *         description: Filter by leave request status
 *       - in: query
 *         name: leaveType
 *         schema:
 *           type: string
 *           enum: [annual, sick, maternity, paternity, emergency, all]
 *           default: all
 *         description: Filter by leave type
 *       - in: query
 *         name: employeeId
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by employee ID
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Filter from start date (YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Filter to end date (YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: Leave requests retrieved successfully
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
 *                         leaveRequests:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LeaveRequest'
 *                         pagination:
 *                           $ref: '#/components/schemas/Pagination'
 *                         filters:
 *                           type: object
 *                           properties:
 *                             status:
 *                               type: string
 *                               description: Applied status filter
 *                             leaveType:
 *                               type: string
 *                               description: Applied leave type filter
 *                             employeeId:
 *                               type: string
 *                               description: Applied employee filter
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
// Get all leave requests
router.get('/', async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 10, 1), 100);
    const offset = (page - 1) * limit;

    const statusFilter = (req.query.status || 'all').toLowerCase();
    const leaveTypeFilter = (req.query.leaveType || 'all').toLowerCase();
    const employeeIdFilter = req.query.employeeId || null;
    const startDateFilter = req.query.startDate || null;
    const endDateFilter = req.query.endDate || null;

    const whereClause = {};

    if (!req.user.is_super_admin) {
      whereClause.organization_id = req.user.organization_id;
    }

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
    } else if (employeeIdFilter) {
      whereClause.employee_id = employeeIdFilter;
    }

    if (statusFilter !== 'all') {
      whereClause.status = statusFilter;
    }

    if (leaveTypeFilter !== 'all') {
      whereClause.leave_type = leaveTypeFilter;
    }

    if (startDateFilter || endDateFilter) {
      if (startDateFilter) {
        whereClause.start_date = {
          ...(whereClause.start_date || {}),
          [Op.gte]: startDateFilter,
        };
      }
      if (endDateFilter) {
        whereClause.end_date = {
          ...(whereClause.end_date || {}),
          [Op.lte]: endDateFilter,
        };
      }
    }

    const { count, rows } = await LeaveRequest.findAndCountAll({
      where: whereClause,
      order: [['created_at', 'DESC']],
      limit,
      offset,
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'name', 'organization_id'],
        },
        {
          model: User,
          as: 'approvedBy',
          attributes: ['id', 'name'],
        },
      ],
    });

    const responsePayload = rows.map(formatLeaveRequestResponse);

    res.success({
      leaveRequests: responsePayload,
      pagination: {
        page,
        limit,
        total: count,
        totalPages: Math.ceil(count / limit) || 0,
      },
      filters: {
        status: statusFilter,
        leaveType: leaveTypeFilter,
        employeeId: employeeIdFilter || (req.user.role === 'employee' ? whereClause.employee_id : 'all'),
      },
    }, 'Leave requests retrieved successfully');
  } catch (error) {
    console.error('Get leave requests error:', error);
    res.error('Failed to fetch leave requests', 500);
  }
});

// Create new leave request
router.post('/', createLeaveRequestValidation, async (req, res) => {
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

    const {
      leaveType,
      startDate,
      endDate,
      reason,
      halfDay = false,
      employeeId,
    } = req.body;

    const parsedStart = new Date(startDate);
    const parsedEnd = new Date(endDate);

    if (Number.isNaN(parsedStart.getTime()) || Number.isNaN(parsedEnd.getTime())) {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid start or end date',
        code: 400,
      });
    }

    if (parsedEnd < parsedStart) {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'End date cannot be before start date',
        code: 400,
      });
    }

    let targetEmployee;

    if (employeeId) {
      targetEmployee = await Employee.findByPk(employeeId, { transaction });
      if (!targetEmployee) {
        targetEmployee = await Employee.findOne({
          where: { user_id: employeeId },
          transaction,
        });
      }
      if (!targetEmployee) {
        await transaction.rollback();
        return res.status(404).json({
          error: 'Not Found',
          message: 'Employee not found',
          code: 404,
        });
      }
    } else {
      targetEmployee = await Employee.findOne({
        where: { user_id: req.user.id },
        transaction,
      });
      if (!targetEmployee) {
        await transaction.rollback();
        return res.status(400).json({
          error: 'Validation Error',
          message: 'Employee profile not found for current user',
          code: 400,
        });
      }
    }

    if (!req.user.is_super_admin) {
      if (req.user.role === 'employee' && targetEmployee.user_id !== req.user.id) {
        await transaction.rollback();
        return res.status(403).json({
          error: 'Forbidden',
          message: 'Employees can only create leave requests for themselves',
          code: 403,
        });
      }

      if (targetEmployee.organization_id !== req.user.organization_id) {
        await transaction.rollback();
        return res.status(403).json({
          error: 'Forbidden',
          message: 'Employee belongs to a different organization',
          code: 403,
        });
      }
    }

    const leaveRequest = await LeaveRequest.create({
      organization_id: targetEmployee.organization_id,
      employee_id: targetEmployee.id,
      leave_type: leaveType,
      start_date: parsedStart.toISOString().split('T')[0],
      end_date: parsedEnd.toISOString().split('T')[0],
      reason,
      half_day: Boolean(halfDay),
      status: 'pending',
      requested_by: req.user.id,
    }, { transaction });

    await transaction.commit();

    const createdWithRelations = await LeaveRequest.findByPk(leaveRequest.id, {
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'name', 'organization_id'],
        },
        {
          model: User,
          as: 'approvedBy',
          attributes: ['id', 'name'],
        },
      ],
    });

    const formatted = formatLeaveRequestResponse(createdWithRelations);

    res.status(201).json({
      message: 'Leave request created successfully',
      data: formatted,
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Create leave request error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to create leave request',
      code: 500,
    });
  }
});

// Get leave request by ID
router.get('/:leaveId', param('leaveId').isUUID(), async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid leave request ID',
        details: errors.array(),
        code: 400,
      });
    }

    // TODO: Implement get leave request by ID with employee details
    res.status(200).json({
      data: {
        id: req.params.leaveId,
        leaveType: 'annual',
        startDate: new Date().toISOString(),
        endDate: new Date().toISOString(),
        reason: 'Sample reason',
        status: 'pending',
        halfDay: false
      },
      message: 'Leave request details - Ready for implementation'
    });
  } catch (error) {
    console.error('Get leave request error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch leave request',
      code: 500,
    });
  }
});

// Update leave request (only if pending)
router.put('/:leaveId', updateLeaveRequestValidation, async (req, res) => {
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

    // TODO: Implement leave request update (check if pending and user owns it)
    res.status(200).json({
      message: 'Leave request updated successfully - Ready for implementation',
      data: {
        id: req.params.leaveId,
        ...req.body
      }
    });
  } catch (error) {
    console.error('Update leave request error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update leave request',
      code: 500,
    });
  }
});

// Approve leave request (Admin only)
router.post('/:leaveId/approve', requireAdmin, approveRejectValidation, async (req, res) => {
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

    const { leaveId } = req.params;
    const { comments } = req.body;

    const leaveRequest = await LeaveRequest.findByPk(leaveId, {
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'organization_id'],
        },
      ],
      transaction,
    });

    if (!leaveRequest) {
      await transaction.rollback();
      return res.status(404).json({
        error: 'Not Found',
        message: 'Leave request not found',
        code: 404,
      });
    }

    if (!req.user.is_super_admin && leaveRequest.organization_id !== req.user.organization_id) {
      await transaction.rollback();
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this leave request',
        code: 403,
      });
    }

    if (leaveRequest.status !== 'pending') {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Only pending leave requests can be approved',
        code: 400,
      });
    }

    await leaveRequest.update({
      status: 'approved',
      approved_by: req.user.id,
      approved_at: new Date(),
      comments: comments || null,
    }, { transaction });

    await transaction.commit();

    const updated = await LeaveRequest.findByPk(leaveId, {
      include: [
        { model: Employee, as: 'employee', attributes: ['id', 'name'] },
        { model: User, as: 'approvedBy', attributes: ['id', 'name'] },
      ],
    });

    res.status(200).json({
      message: 'Leave request approved successfully',
      data: formatLeaveRequestResponse(updated),
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Approve leave request error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to approve leave request',
      code: 500,
    });
  }
});

// Reject leave request (Admin only)
router.post('/:leaveId/reject', requireAdmin, approveRejectValidation, async (req, res) => {
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

    const { leaveId } = req.params;
    const { comments } = req.body;

    const leaveRequest = await LeaveRequest.findByPk(leaveId, {
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'organization_id'],
        },
      ],
      transaction,
    });

    if (!leaveRequest) {
      await transaction.rollback();
      return res.status(404).json({
        error: 'Not Found',
        message: 'Leave request not found',
        code: 404,
      });
    }

    if (!req.user.is_super_admin && leaveRequest.organization_id !== req.user.organization_id) {
      await transaction.rollback();
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this leave request',
        code: 403,
      });
    }

    if (leaveRequest.status !== 'pending') {
      await transaction.rollback();
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Only pending leave requests can be rejected',
        code: 400,
      });
    }

    await leaveRequest.update({
      status: 'rejected',
      approved_by: req.user.id,
      approved_at: new Date(),
      comments: comments || null,
    }, { transaction });

    await transaction.commit();

    const updatedLeave = await LeaveRequest.findByPk(leaveId, {
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'name', 'organization_id'],
        },
        {
          model: User,
          as: 'approvedBy',
          attributes: ['id', 'name'],
        },
      ],
    });

    res.status(200).json({
      message: 'Leave request rejected successfully',
      data: formatLeaveRequestResponse(updatedLeave),
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Reject leave request error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to reject leave request',
      code: 500,
    });
  }
});

// Delete leave request (only if pending and user owns it)
router.delete('/:leaveId', param('leaveId').isUUID(), async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid leave request ID',
        details: errors.array(),
        code: 400,
      });
    }

    // TODO: Implement leave request deletion (check permissions and status)
    res.status(200).json({
      message: 'Leave request deleted successfully - Ready for implementation'
    });
  } catch (error) {
    console.error('Delete leave request error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to delete leave request',
      code: 500,
    });
  }
});

module.exports = router;
