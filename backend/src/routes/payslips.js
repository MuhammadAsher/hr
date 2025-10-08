const express = require('express');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticateToken);

// Placeholder routes
router.get('/', (req, res) => {
  res.status(200).json({
    data: [],
    message: 'Payslips endpoint - coming soon',
  });
});

router.post('/', (req, res) => {
  res.status(201).json({
    message: 'Generate payslip endpoint - coming soon',
  });
});

module.exports = router;
