const express = require('express');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticateToken);

// Placeholder routes
router.get('/employees', (req, res) => {
  res.status(200).json({
    data: {},
    message: 'Employee reports endpoint - coming soon',
  });
});

router.get('/leave', (req, res) => {
  res.status(200).json({
    data: {},
    message: 'Leave reports endpoint - coming soon',
  });
});

router.get('/attendance', (req, res) => {
  res.status(200).json({
    data: {},
    message: 'Attendance reports endpoint - coming soon',
  });
});

module.exports = router;
