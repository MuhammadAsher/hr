const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'HR Management Platform API',
      version: '1.0.0',
      description: 'A comprehensive HR Management Platform API with authentication, employee management, attendance tracking, task management, leave requests, and payroll features.',
      contact: {
        name: 'HR Platform API Support',
        email: 'support@hrplatform.com',
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT',
      },
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server',
      },
      {
        url: 'https://api.hrplatform.com',
        description: 'Production server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Enter JWT token obtained from login endpoint',
        },
      },
      schemas: {
        ApiResponse: {
          type: 'object',
          properties: {
            status: {
              type: 'boolean',
              description: 'Indicates if the request was successful',
              example: true,
            },
            message: {
              type: 'string',
              description: 'Human-readable message describing the result',
              example: 'Operation completed successfully',
            },
            data: {
              type: 'object',
              description: 'Response data payload',
            },
          },
          required: ['status', 'message', 'data'],
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            status: {
              type: 'boolean',
              description: 'Always false for error responses',
              example: false,
            },
            message: {
              type: 'string',
              description: 'Error message',
              example: 'An error occurred',
            },
            error: {
              type: 'string',
              description: 'Error type',
              example: 'ValidationError',
            },
            code: {
              type: 'integer',
              description: 'HTTP status code',
              example: 400,
            },
            data: {
              type: 'object',
              description: 'Additional error details',
              properties: {
                details: {
                  type: 'array',
                  items: {
                    type: 'string',
                  },
                  description: 'Detailed error information',
                },
              },
            },
          },
          required: ['status', 'message', 'error', 'code', 'data'],
        },
        User: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Unique user identifier',
              example: 'ac1a17d8-b9c4-4c8a-8e5f-1234567890ab',
            },
            name: {
              type: 'string',
              description: 'Full name of the user',
              example: 'Admin User',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'User email address',
              example: 'admin@hr.com',
            },
            role: {
              type: 'string',
              enum: ['super_admin', 'admin', 'employee'],
              description: 'User role in the system',
              example: 'admin',
            },
            organizationId: {
              type: 'string',
              format: 'uuid',
              description: 'Organization the user belongs to',
              example: 'org-123e4567-e89b-12d3-a456-426614174000',
            },
            isActive: {
              type: 'boolean',
              description: 'Whether the user account is active',
              example: true,
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Account creation timestamp',
              example: '2024-01-01T00:00:00.000Z',
            },
          },
        },
        LoginRequest: {
          type: 'object',
          required: ['email', 'password', 'role'],
          properties: {
            email: {
              type: 'string',
              format: 'email',
              description: 'User email address',
              example: 'admin@hr.com',
            },
            password: {
              type: 'string',
              description: 'User password',
              example: 'admin123',
            },
            role: {
              type: 'string',
              enum: ['admin', 'employee'],
              description: 'User role for login',
              example: 'admin',
            },
          },
        },
        LoginResponse: {
          allOf: [
            { $ref: '#/components/schemas/ApiResponse' },
            {
              type: 'object',
              properties: {
                data: {
                  type: 'object',
                  properties: {
                    token: {
                      type: 'string',
                      description: 'JWT access token',
                      example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                    },
                    refreshToken: {
                      type: 'string',
                      description: 'JWT refresh token',
                      example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                    },
                    user: {
                      $ref: '#/components/schemas/User',
                    },
                    expiresIn: {
                      type: 'integer',
                      description: 'Token expiration time in seconds',
                      example: 86400,
                    },
                  },
                },
              },
            },
          ],
        },
        Pagination: {
          type: 'object',
          properties: {
            page: {
              type: 'integer',
              description: 'Current page number',
              example: 1,
            },
            limit: {
              type: 'integer',
              description: 'Number of items per page',
              example: 10,
            },
            total: {
              type: 'integer',
              description: 'Total number of items',
              example: 0,
            },
            totalPages: {
              type: 'integer',
              description: 'Total number of pages',
              example: 0,
            },
          },
        },
        Department: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Department unique identifier',
              example: 'dept-123e4567-e89b-12d3-a456-426614174000',
            },
            name: {
              type: 'string',
              description: 'Department name',
              example: 'Human Resources',
            },
            description: {
              type: 'string',
              description: 'Department description',
              example: 'Manages employee relations and policies',
            },
            managerId: {
              type: 'string',
              format: 'uuid',
              description: 'Department manager user ID',
              example: 'user-123e4567-e89b-12d3-a456-426614174000',
            },
            organizationId: {
              type: 'string',
              format: 'uuid',
              description: 'Organization ID',
              example: 'org-123e4567-e89b-12d3-a456-426614174000',
            },
            isActive: {
              type: 'boolean',
              description: 'Whether the department is active',
              example: true,
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Creation timestamp',
              example: '2024-01-01T00:00:00.000Z',
            },
          },
        },
        Task: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Task unique identifier',
            },
            title: {
              type: 'string',
              description: 'Task title',
            },
            description: {
              type: 'string',
              description: 'Task description',
            },
            status: {
              type: 'string',
              enum: ['pending', 'in_progress', 'completed', 'cancelled'],
              description: 'Task status',
            },
            priority: {
              type: 'string',
              enum: ['low', 'medium', 'high', 'urgent'],
              description: 'Task priority',
            },
            assignedTo: {
              type: 'string',
              format: 'uuid',
              description: 'Assigned employee ID',
            },
            dueDate: {
              type: 'string',
              format: 'date-time',
              description: 'Task due date',
            },
          },
        },
        LeaveRequest: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Leave request unique identifier',
            },
            employeeId: {
              type: 'string',
              format: 'uuid',
              description: 'Employee ID',
            },
            leaveType: {
              type: 'string',
              enum: ['annual', 'sick', 'maternity', 'paternity', 'emergency'],
              description: 'Type of leave',
            },
            startDate: {
              type: 'string',
              format: 'date',
              description: 'Leave start date',
            },
            endDate: {
              type: 'string',
              format: 'date',
              description: 'Leave end date',
            },
            status: {
              type: 'string',
              enum: ['pending', 'approved', 'rejected'],
              description: 'Leave request status',
            },
            reason: {
              type: 'string',
              description: 'Reason for leave',
            },
          },
        },
        Employee: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Employee unique identifier',
            },
            employeeId: {
              type: 'string',
              description: 'Employee number/ID',
            },
            firstName: {
              type: 'string',
              description: 'Employee first name',
            },
            lastName: {
              type: 'string',
              description: 'Employee last name',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'Employee email address',
            },
            department: {
              type: 'string',
              description: 'Department name',
            },
            position: {
              type: 'string',
              description: 'Job position',
            },
            hireDate: {
              type: 'string',
              format: 'date',
              description: 'Employee hire date',
            },
            salary: {
              type: 'number',
              description: 'Employee salary',
            },
            status: {
              type: 'string',
              enum: ['active', 'inactive', 'on_leave', 'terminated'],
              description: 'Employee status',
            },
            managerId: {
              type: 'string',
              format: 'uuid',
              description: 'Manager employee ID',
            },
            phone: {
              type: 'string',
              description: 'Employee phone number',
            },
            address: {
              type: 'string',
              description: 'Employee address',
            },
          },
        },
        Payslip: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Payslip unique identifier',
            },
            employeeId: {
              type: 'string',
              format: 'uuid',
              description: 'Employee ID',
            },
            payPeriodStart: {
              type: 'string',
              format: 'date',
              description: 'Pay period start date',
            },
            payPeriodEnd: {
              type: 'string',
              format: 'date',
              description: 'Pay period end date',
            },
            basicSalary: {
              type: 'number',
              description: 'Basic salary amount',
            },
            allowances: {
              type: 'number',
              description: 'Total allowances',
            },
            deductions: {
              type: 'number',
              description: 'Total deductions',
            },
            netSalary: {
              type: 'number',
              description: 'Net salary after deductions',
            },
            status: {
              type: 'string',
              enum: ['draft', 'processed', 'paid'],
              description: 'Payslip status',
            },
          },
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  apis: ['./src/routes/*.js'], // Path to the API routes
};

const specs = swaggerJsdoc(options);

module.exports = {
  specs,
  swaggerUi,
  serve: swaggerUi.serve,
  setup: swaggerUi.setup(specs, {
    explorer: true,
    customCss: `
      .swagger-ui .topbar { display: none }
      .swagger-ui .info { margin: 20px 0 }
      .swagger-ui .info .title { color: #3b4151; font-size: 36px }
    `,
    customSiteTitle: 'HR Platform API Documentation',
    swaggerOptions: {
      persistAuthorization: true,
      displayRequestDuration: true,
      docExpansion: 'list',
      filter: true,
      showExtensions: true,
      showCommonExtensions: true,
      tryItOutEnabled: true,
    },
  }),
};
