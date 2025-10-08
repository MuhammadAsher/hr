const jwt = require('jsonwebtoken');
const { User, Organization } = require('../models');

// Verify JWT token
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Access token is required',
        code: 401,
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Find user
    const user = await User.findByPk(decoded.userId, {
      include: [
        {
          model: Organization,
          as: 'organization',
          attributes: ['id', 'name', 'is_active'],
        },
      ],
    });

    if (!user || !user.is_active) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'User not found or inactive',
        code: 401,
      });
    }

    // Check if organization is active (except for super admin)
    if (!user.is_super_admin && user.organization && !user.organization.is_active) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Organization is inactive',
        code: 403,
      });
    }

    // Attach user to request
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid token',
        code: 401,
      });
    } else if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Token expired',
        code: 401,
      });
    }

    console.error('Auth middleware error:', error);
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Authentication failed',
      code: 500,
    });
  }
};

// Check if user is super admin
const requireSuperAdmin = (req, res, next) => {
  if (!req.user || !req.user.is_super_admin) {
    return res.status(403).json({
      error: 'Forbidden',
      message: 'Super admin access required',
      code: 403,
    });
  }
  next();
};

// Check if user is admin (organization admin or super admin)
const requireAdmin = (req, res, next) => {
  if (!req.user || (req.user.role !== 'admin' && !req.user.is_super_admin)) {
    return res.status(403).json({
      error: 'Forbidden',
      message: 'Admin access required',
      code: 403,
    });
  }
  next();
};

// Check if user can access organization data
const requireOrganizationAccess = (organizationIdParam = 'organizationId') => {
  return (req, res, next) => {
    const requestedOrgId = req.params[organizationIdParam] || req.body.organizationId;
    
    // Super admin can access any organization
    if (req.user.is_super_admin) {
      return next();
    }
    
    // Regular users can only access their own organization
    if (!requestedOrgId || requestedOrgId !== req.user.organization_id) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Access denied to this organization',
        code: 403,
      });
    }
    
    next();
  };
};

// Middleware to add organization filter to queries
const addOrganizationFilter = (req, res, next) => {
  // Super admin doesn't need organization filter
  if (req.user.is_super_admin) {
    return next();
  }
  
  // Add organization filter to request
  req.organizationFilter = {
    organization_id: req.user.organization_id,
  };
  
  next();
};

// Generate JWT token
const generateToken = (user) => {
  const payload = {
    userId: user.id,
    email: user.email,
    role: user.role,
    organizationId: user.organization_id,
    isSuperAdmin: user.is_super_admin,
  };

  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
  });
};

// Generate refresh token
const generateRefreshToken = (user) => {
  const payload = {
    userId: user.id,
    type: 'refresh',
  };

  return jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  });
};

// Verify refresh token
const verifyRefreshToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_REFRESH_SECRET);
  } catch (error) {
    throw new Error('Invalid refresh token');
  }
};

module.exports = {
  authenticateToken,
  requireSuperAdmin,
  requireAdmin,
  requireOrganizationAccess,
  addOrganizationFilter,
  generateToken,
  generateRefreshToken,
  verifyRefreshToken,
};
