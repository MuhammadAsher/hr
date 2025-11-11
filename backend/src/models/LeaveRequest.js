const { DataTypes } = require('sequelize');
const { sequelize } = require('../database/connection');

const LeaveRequest = sequelize.define('LeaveRequest', {
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
  employee_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'employees',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  leave_type: {
    type: DataTypes.ENUM('annual', 'sick', 'personal', 'maternity', 'paternity', 'emergency'),
    allowNull: false,
    defaultValue: 'annual',
  },
  start_date: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  end_date: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  reason: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM('pending', 'approved', 'rejected', 'cancelled'),
    allowNull: false,
    defaultValue: 'pending',
  },
  half_day: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  requested_by: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id',
    },
    onDelete: 'SET NULL',
  },
  approved_by: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id',
    },
    onDelete: 'SET NULL',
  },
  approved_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  comments: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
}, {
  tableName: 'leave_requests',
  indexes: [
    {
      fields: ['organization_id'],
    },
    {
      fields: ['employee_id'],
    },
    {
      fields: ['status'],
    },
    {
      fields: ['leave_type'],
    },
    {
      fields: ['start_date'],
    },
  ],
});

module.exports = LeaveRequest;
