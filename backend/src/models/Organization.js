const { DataTypes } = require('sequelize');
const { sequelize } = require('../database/connection');

const Organization = sequelize.define('Organization', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [2, 255],
    },
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true,
    },
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: true,
    validate: {
      len: [10, 20],
    },
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  industry: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      notEmpty: true,
    },
  },
  logo: {
    type: DataTypes.STRING,
    allowNull: true,
    validate: {
      isUrl: true,
    },
  },
  registered_date: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  subscription_plan: {
    type: DataTypes.ENUM('Free', 'Basic', 'Premium', 'Enterprise'),
    allowNull: false,
    defaultValue: 'Free',
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  employee_limit: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 10,
    validate: {
      min: 1,
    },
  },
  settings: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: {
      workingHours: '9:00 AM - 5:00 PM',
      workingDays: 'Monday - Friday',
      currency: 'USD',
      dateFormat: 'MM/DD/YYYY',
      timeZone: 'UTC',
    },
  },
  admin_id: {
    type: DataTypes.UUID,
    allowNull: true, // Will be set after admin user is created
  },
  tax_id: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  website: {
    type: DataTypes.STRING,
    allowNull: true,
    validate: {
      isUrl: true,
    },
  },
}, {
  tableName: 'organizations',
  indexes: [
    {
      fields: ['email'],
      unique: true,
    },
    {
      fields: ['is_active'],
    },
    {
      fields: ['subscription_plan'],
    },
  ],
});

// Class methods
Organization.getSubscriptionLimits = function() {
  return {
    Free: { employees: 10, price: 0 },
    Basic: { employees: 50, price: 29 },
    Premium: { employees: 200, price: 99 },
    Enterprise: { employees: -1, price: 299 }, // -1 means unlimited
  };
};

// Instance methods
Organization.prototype.canAddEmployee = async function() {
  if (this.employee_limit === -1) return true; // Unlimited
  
  const currentCount = await this.countUsers({
    where: { role: ['admin', 'employee'] }
  });
  
  return currentCount < this.employee_limit;
};

Organization.prototype.getUsagePercentage = async function() {
  if (this.employee_limit === -1) return 0; // Unlimited plan
  
  const currentCount = await this.countUsers({
    where: { role: ['admin', 'employee'] }
  });
  
  return Math.round((currentCount / this.employee_limit) * 100);
};

module.exports = Organization;
