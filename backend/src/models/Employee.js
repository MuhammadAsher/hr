const { DataTypes } = require('sequelize');
const { sequelize } = require('../database/connection');

const Employee = sequelize.define('Employee', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  organization_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'organizations',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: true, // Employee might not have a user account yet
    references: {
      model: 'users',
      key: 'id',
    },
    onDelete: 'SET NULL',
  },
  employee_id: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      notEmpty: true,
    },
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
  department: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      notEmpty: true,
    },
  },
  position: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      notEmpty: true,
    },
  },
  join_date: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  salary: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    validate: {
      min: 0,
    },
  },
  status: {
    type: DataTypes.ENUM('active', 'inactive', 'on_leave', 'terminated'),
    allowNull: false,
    defaultValue: 'active',
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  emergency_contact: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: {},
    validate: {
      isValidEmergencyContact(value) {
        if (value && typeof value === 'object') {
          const { name, phone, relationship } = value;
          if (name && typeof name !== 'string') {
            throw new Error('Emergency contact name must be a string');
          }
          if (phone && typeof phone !== 'string') {
            throw new Error('Emergency contact phone must be a string');
          }
          if (relationship && typeof relationship !== 'string') {
            throw new Error('Emergency contact relationship must be a string');
          }
        }
      },
    },
  },
  date_of_birth: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  hire_date: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  termination_date: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  manager_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'employees',
      key: 'id',
    },
  },
  profile_picture: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'employees',
  indexes: [
    {
      fields: ['organization_id'],
    },
    {
      fields: ['employee_id', 'organization_id'],
      unique: true,
      name: 'unique_employee_id_per_organization',
    },
    {
      fields: ['email', 'organization_id'],
      unique: true,
      name: 'unique_employee_email_per_organization',
    },
    {
      fields: ['department'],
    },
    {
      fields: ['status'],
    },
    {
      fields: ['manager_id'],
    },
  ],
});

// Instance methods
Employee.prototype.getFullName = function() {
  return this.name;
};

Employee.prototype.isActive = function() {
  return this.status === 'active';
};

Employee.prototype.getYearsOfService = function() {
  const now = new Date();
  const joinDate = new Date(this.join_date);
  return Math.floor((now - joinDate) / (365.25 * 24 * 60 * 60 * 1000));
};

// Class methods
Employee.findByOrganization = async function(organizationId, options = {}) {
  return this.findAll({
    where: {
      organization_id: organizationId,
      ...options.where,
    },
    ...options,
  });
};

Employee.findActiveByOrganization = async function(organizationId) {
  return this.findByOrganization(organizationId, {
    where: { status: 'active' },
  });
};

Employee.generateEmployeeId = async function(organizationId) {
  const count = await this.count({
    where: { organization_id: organizationId },
  });
  
  const orgPrefix = organizationId.substring(0, 3).toUpperCase();
  const empNumber = String(count + 1).padStart(4, '0');
  
  return `${orgPrefix}${empNumber}`;
};

module.exports = Employee;
