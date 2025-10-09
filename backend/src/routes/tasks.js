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
 *   name: Tasks
 *   description: Task management and assignment
 */

// Apply authentication to all routes
router.use(authenticateToken);

// Validation rules
const createTaskValidation = [
  body('title').trim().isLength({ min: 3, max: 200 }).withMessage('Task title must be 3-200 characters'),
  body('description').optional().trim().isLength({ max: 1000 }).withMessage('Description must be less than 1000 characters'),
  body('assignedTo').optional().isUUID().withMessage('Valid employee ID required'),
  body('priority').optional().isIn(['low', 'medium', 'high', 'urgent']).withMessage('Priority must be low, medium, high, or urgent'),
  body('status').optional().isIn(['pending', 'in_progress', 'completed', 'cancelled']).withMessage('Invalid status'),
  body('dueDate').optional().isISO8601().withMessage('Valid due date required'),
];

const updateTaskValidation = [
  param('taskId').isUUID().withMessage('Valid task ID required'),
  body('title').optional().trim().isLength({ min: 3, max: 200 }).withMessage('Task title must be 3-200 characters'),
  body('description').optional().trim().isLength({ max: 1000 }).withMessage('Description must be less than 1000 characters'),
  body('assignedTo').optional().isUUID().withMessage('Valid employee ID required'),
  body('priority').optional().isIn(['low', 'medium', 'high', 'urgent']).withMessage('Priority must be low, medium, high, or urgent'),
  body('status').optional().isIn(['pending', 'in_progress', 'completed', 'cancelled']).withMessage('Invalid status'),
  body('dueDate').optional().isISO8601().withMessage('Valid due date required'),
];

/**
 * @swagger
 * /api/v1/tasks:
 *   get:
 *     summary: Get all tasks
 *     description: Retrieve a paginated list of tasks with filtering options
 *     tags: [Tasks]
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
 *           enum: [pending, in_progress, completed, cancelled, all]
 *           default: all
 *         description: Filter by task status
 *       - in: query
 *         name: priority
 *         schema:
 *           type: string
 *           enum: [low, medium, high, urgent, all]
 *           default: all
 *         description: Filter by task priority
 *       - in: query
 *         name: assignedTo
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by assigned employee ID
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search in task title and description
 *     responses:
 *       200:
 *         description: Tasks retrieved successfully
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
 *                         tasks:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/Task'
 *                         pagination:
 *                           $ref: '#/components/schemas/Pagination'
 *                         filters:
 *                           type: object
 *                           properties:
 *                             status:
 *                               type: string
 *                               description: Applied status filter
 *                             priority:
 *                               type: string
 *                               description: Applied priority filter
 *                             assignedTo:
 *                               type: string
 *                               description: Applied assignee filter
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
// Get all tasks
router.get('/', async (req, res) => {
  try {
    // TODO: Implement task listing with filtering by status, priority, assignee, due date
    res.success({
      tasks: [],
      pagination: {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 10,
        total: 0,
        totalPages: 0
      },
      filters: {
        status: req.query.status || 'all',
        priority: req.query.priority || 'all',
        assignedTo: req.query.assignedTo || 'all'
      }
    }, 'Task listing - Ready for implementation');
  } catch (error) {
    console.error('Get tasks error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch tasks',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/tasks/{taskId}:
 *   get:
 *     summary: Get task by ID
 *     description: Retrieve a specific task by its ID
 *     tags: [Tasks]
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Task ID
 *     responses:
 *       200:
 *         description: Task retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Task'
 *       400:
 *         description: Invalid task ID
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
 *         description: Task not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Get task by ID
router.get('/:taskId', param('taskId').isUUID(), async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid task ID',
        details: errors.array(),
        code: 400,
      });
    }

    // TODO: Implement get task by ID with assignee details
    res.status(200).json({
      data: {
        id: req.params.taskId,
        title: 'Sample Task',
        description: 'Task description',
        status: 'pending',
        priority: 'medium',
        assignedTo: null,
        dueDate: null,
        createdAt: new Date().toISOString()
      },
      message: 'Task details - Ready for implementation'
    });
  } catch (error) {
    console.error('Get task error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch task',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/tasks:
 *   post:
 *     summary: Create new task
 *     description: Create a new task with the provided details
 *     tags: [Tasks]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [title, description, assignedTo, dueDate]
 *             properties:
 *               title:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 200
 *                 description: Task title
 *                 example: "Complete project documentation"
 *               description:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 1000
 *                 description: Task description
 *                 example: "Write comprehensive documentation for the HR platform"
 *               assignedTo:
 *                 type: string
 *                 format: uuid
 *                 description: Employee ID to assign the task to
 *                 example: "123e4567-e89b-12d3-a456-426614174000"
 *               priority:
 *                 type: string
 *                 enum: [low, medium, high, urgent]
 *                 default: medium
 *                 description: Task priority
 *                 example: "high"
 *               status:
 *                 type: string
 *                 enum: [pending, in_progress, completed, cancelled]
 *                 default: pending
 *                 description: Task status
 *                 example: "pending"
 *               dueDate:
 *                 type: string
 *                 format: date-time
 *                 description: Task due date
 *                 example: "2024-12-31T23:59:59.000Z"
 *     responses:
 *       201:
 *         description: Task created successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Task'
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
 */
// Create new task
router.post('/', createTaskValidation, async (req, res) => {
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

    // TODO: Implement task creation
    res.status(201).json({
      message: 'Task created successfully - Ready for implementation',
      data: {
        id: 'temp-id',
        title: req.body.title,
        description: req.body.description || null,
        assignedTo: req.body.assignedTo || null,
        priority: req.body.priority || 'medium',
        status: req.body.status || 'pending',
        dueDate: req.body.dueDate || null,
        createdBy: req.user.userId
      }
    });
  } catch (error) {
    console.error('Create task error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to create task',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/tasks/{taskId}:
 *   put:
 *     summary: Update task
 *     description: Update an existing task with new details
 *     tags: [Tasks]
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Task ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 200
 *                 description: Task title
 *               description:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 1000
 *                 description: Task description
 *               assignedTo:
 *                 type: string
 *                 format: uuid
 *                 description: Employee ID to assign the task to
 *               priority:
 *                 type: string
 *                 enum: [low, medium, high, urgent]
 *                 description: Task priority
 *               status:
 *                 type: string
 *                 enum: [pending, in_progress, completed, cancelled]
 *                 description: Task status
 *               dueDate:
 *                 type: string
 *                 format: date-time
 *                 description: Task due date
 *     responses:
 *       200:
 *         description: Task updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Task'
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
 *       404:
 *         description: Task not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Update task
router.put('/:taskId', updateTaskValidation, async (req, res) => {
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

    // TODO: Implement task update (check permissions)
    res.status(200).json({
      message: 'Task updated successfully - Ready for implementation',
      data: {
        id: req.params.taskId,
        ...req.body
      }
    });
  } catch (error) {
    console.error('Update task error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update task',
      code: 500,
    });
  }
});

/**
 * @swagger
 * /api/v1/tasks/{taskId}:
 *   delete:
 *     summary: Delete task
 *     description: Delete a task by its ID
 *     tags: [Tasks]
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Task ID
 *     responses:
 *       200:
 *         description: Task deleted successfully
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
 *                         deletedTaskId:
 *                           type: string
 *                           format: uuid
 *                           description: ID of the deleted task
 *       400:
 *         description: Invalid task ID
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
 *         description: Task not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
// Delete task
router.delete('/:taskId', param('taskId').isUUID(), async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Invalid task ID',
        details: errors.array(),
        code: 400,
      });
    }

    // TODO: Implement task deletion (check permissions)
    res.status(200).json({
      message: 'Task deleted successfully - Ready for implementation'
    });
  } catch (error) {
    console.error('Delete task error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to delete task',
      code: 500,
    });
  }
});

module.exports = router;
