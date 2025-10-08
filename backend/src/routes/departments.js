const express = require('express');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticateToken);

// Placeholder routes
router.get('/', (req, res) => {
  res.status(200).json({
    data: [],
    message: 'Departments endpoint - coming soon',
  });
});

router.post('/', (req, res) => {
  res.status(201).json({
    message: 'Create department endpoint - coming soon',
  });
});

module.exports = router;
