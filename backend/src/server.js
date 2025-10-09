const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const responseFormatter = require('./middleware/response');
require('dotenv').config();

const { sequelize } = require('./database/connection');
const authRoutes = require('./routes/auth');
const organizationRoutes = require('./routes/organizations');
const employeeRoutes = require('./routes/employees');
const leaveRoutes = require('./routes/leave-requests');
const attendanceRoutes = require('./routes/attendance');
const taskRoutes = require('./routes/tasks');
const departmentRoutes = require('./routes/departments');
const payslipRoutes = require('./routes/payslips');
const reportRoutes = require('./routes/reports');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(compression());

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
});
app.use('/api/', limiter);

// CORS configuration - Allow all origins for development
const corsOptions = {
  origin: true, // Allow all origins in development
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};
app.use(cors(corsOptions));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Response formatting middleware
app.use(responseFormatter);

// Swagger Documentation
const { serve, setup } = require('./config/swagger');
app.use('/api-docs', serve, setup);

// Serve static files from public directory
app.use(express.static('public'));

// Logging middleware
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined'));
}

/**
 * @swagger
 * /health:
 *   get:
 *     summary: Health check
 *     description: Check if the server is running and healthy
 *     tags: [System]
 *     security: []
 *     responses:
 *       200:
 *         description: Server is healthy
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
 *                         timestamp:
 *                           type: string
 *                           format: date-time
 *                           description: Current server timestamp
 *                           example: "2024-01-01T00:00:00.000Z"
 *                         uptime:
 *                           type: number
 *                           description: Server uptime in seconds
 *                           example: 123.456
 *                         environment:
 *                           type: string
 *                           description: Current environment
 *                           example: "development"
 */
// Health check endpoint
app.get('/health', (req, res) => {
  res.success({
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV,
  }, 'Server is healthy');
});

// API routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/organizations', organizationRoutes);
app.use('/api/v1/employees', employeeRoutes);
app.use('/api/v1/leave-requests', leaveRoutes);
app.use('/api/v1/attendance', attendanceRoutes);
app.use('/api/v1/tasks', taskRoutes);
app.use('/api/v1/departments', departmentRoutes);
app.use('/api/v1/payslips', payslipRoutes);
app.use('/api/v1/reports', reportRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`,
    code: 404,
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  // Default error response
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';
  
  // Handle specific error types
  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = 'Validation Error';
  } else if (err.name === 'UnauthorizedError') {
    statusCode = 401;
    message = 'Unauthorized';
  } else if (err.name === 'SequelizeValidationError') {
    statusCode = 400;
    message = 'Database Validation Error';
  }
  
  res.status(statusCode).json({
    error: err.name || 'Error',
    message: message,
    code: statusCode,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// Database connection and server startup
async function startServer() {
  try {
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connection established successfully.');
    
    // Validate database models (in development)
    if (process.env.NODE_ENV === 'development') {
      await sequelize.sync({ alter: false });
      console.log('✅ Database models validated.');
    }
    
    // Start server
    app.listen(PORT, () => {
      console.log(`🚀 HR Platform API server running on port ${PORT}`);
      console.log(`📚 Environment: ${process.env.NODE_ENV}`);
      console.log(`🔗 Health check: http://localhost:${PORT}/health`);
      console.log(`📖 API Documentation: http://localhost:${PORT}/api-docs`);
    });
  } catch (error) {
    console.error('❌ Unable to start server:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully...');
  await sequelize.close();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully...');
  await sequelize.close();
  process.exit(0);
});

// Start the server
if (require.main === module) {
  startServer();
}

module.exports = app;
