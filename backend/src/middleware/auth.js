const jwt = require('jsonwebtoken');
const { User, Organization } = require('../models');

// Verify JWT token
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.unauthorized('Access token is required');
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Find user
    let user;
    try {
      user = await User.findByPk(decoded.userId, {
        include: [
          {
            model: Organization,
            as: 'organization',
            attributes: ['id', 'name', 'is_active'],
            required: false, // Left join - don't fail if org doesn't exist
          },
        ],
      });
    } catch (dbError) {
      console.error('Database error during user lookup:', dbError);
      return res.error('Database error during authentication', 500);
    }

    if (!user || !user.is_active) {
      return res.unauthorized('User not found or inactive');
    }

    // Check if organization is active (except for super admin)
    if (!user.is_super_admin && user.organization && !user.organization.is_active) {
      return res.forbidden('Organization is inactive');
    }

    // Attach user to request
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.unauthorized('Invalid token');
    } else if (error.name === 'TokenExpiredError') {
      return res.unauthorized('Token expired');
    }

    console.error('Auth middleware error:', error);
    return res.error('Authentication failed', 500);
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
  const jwtSecret = process.env.JWT_SECRET;
  if (!jwtSecret) {
    throw new Error('JWT_SECRET is not configured');
  }

  const payload = {
    userId: user.id,
    email: user.email,
    role: user.role,
    organizationId: user.organization_id,
    isSuperAdmin: user.is_super_admin,
  };

  return jwt.sign(payload, jwtSecret, {
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
  });
};

// Generate refresh token
const generateRefreshToken = (user) => {
  const refreshSecret = process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET;
  if (!refreshSecret) {
    throw new Error('JWT_REFRESH_SECRET is not configured');
  }

  const payload = {
    userId: user.id,
    type: 'refresh',
  };

  return jwt.sign(payload, refreshSecret, {
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

// Optional authentication - verifies token but doesn't require user to exist
// Useful for logout where we want to allow logout even if user is deleted
const optionalAuthenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      // No token provided - that's okay for optional auth
      return next();
    }

    // Verify token format
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // Try to find user, but don't fail if not found
      try {
        const user = await User.findByPk(decoded.userId, {
          include: [
            {
              model: Organization,
              as: 'organization',
              attributes: ['id', 'name', 'is_active'],
              required: false, // Left join - don't fail if org doesn't exist
            },
          ],
        });

        if (user && user.is_active) {
          req.user = user;
        }
      } catch (dbError) {
        // User lookup failed - that's okay, we'll still proceed
        console.warn('User lookup failed during optional auth:', dbError.message);
      }
    } catch (tokenError) {
      // Token is invalid/expired - that's okay for optional auth
      // We'll just proceed without req.user
    }
    
    next();
  } catch (error) {
    // Any other error - log but continue
    console.warn('Optional auth middleware error:', error.message);
    next();
  }
};

module.exports = {
  authenticateToken,
  optionalAuthenticateToken,
  requireSuperAdmin,
  requireAdmin,
  requireOrganizationAccess,
  addOrganizationFilter,
  generateToken,
  generateRefreshToken,
  verifyRefreshToken,
};
