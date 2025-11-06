const { DataTypes } = require('sequelize');
const { sequelize } = require('../database/connection');

const Department = sequelize.define('Department', {
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
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [2, 100],
    },
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
    validate: {
      len: [0, 500],
    },
  },
  manager_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'employees',
      key: 'id',
    },
    onDelete: 'SET NULL',
  },
  budget: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: true,
    validate: {
      min: 0,
    },
  },
  location: {
    type: DataTypes.STRING,
    allowNull: true,
    validate: {
      len: [0, 200],
    },
  },
  status: {
    type: DataTypes.ENUM('active', 'inactive'),
    allowNull: false,
    defaultValue: 'active',
  },
}, {
  tableName: 'departments',
  indexes: [
    {
      fields: ['organization_id'],
    },
    {
      fields: ['name', 'organization_id'],
      unique: true,
      name: 'unique_department_name_per_organization',
    },
    {
      fields: ['manager_id'],
    },
    {
      fields: ['status'],
    },
  ],
});

// Instance methods
Department.prototype.isActive = function() {
  return this.status === 'active';
};

module.exports = Department;

