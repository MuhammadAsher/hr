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
    // TODO: Implement leave request listing with filtering by status, employee, date range
    res.success({
      leaveRequests: [],
      pagination: {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 10,
        total: 0,
        totalPages: 0
      },
      filters: {
        status: req.query.status || 'all',
        leaveType: req.query.leaveType || 'all',
        employeeId: req.query.employeeId || 'all'
      }
    }, 'Leave requests listing - Ready for implementation');
  } catch (error) {
    console.error('Get leave requests error:', error);
    res.error('Failed to fetch leave requests', 500);
  }
});

// Create new leave request
router.post('/', createLeaveRequestValidation, async (req, res) => {
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

    // TODO: Implement leave request creation with date validation
    res.status(201).json({
      message: 'Leave request created successfully - Ready for implementation',
      data: {
        id: 'temp-id',
        leaveType: req.body.leaveType,
        startDate: req.body.startDate,
        endDate: req.body.endDate,
        reason: req.body.reason,
        status: 'pending',
        halfDay: req.body.halfDay || false,
        requestedBy: req.user.userId
      }
    });
  } catch (error) {
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

    // TODO: Implement leave request approval
    res.status(200).json({
      message: 'Leave request approved successfully - Ready for implementation',
      data: {
        id: req.params.leaveId,
        status: 'approved',
        approvedBy: req.user.userId,
        approvedAt: new Date().toISOString(),
        comments: req.body.comments || null
      }
    });
  } catch (error) {
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

    // TODO: Implement leave request rejection
    res.status(200).json({
      message: 'Leave request rejected successfully - Ready for implementation',
      data: {
        id: req.params.leaveId,
        status: 'rejected',
        rejectedBy: req.user.userId,
        rejectedAt: new Date().toISOString(),
        comments: req.body.comments || 'No reason provided'
      }
    });
  } catch (error) {
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
