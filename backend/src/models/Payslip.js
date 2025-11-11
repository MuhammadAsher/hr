const { DataTypes } = require('sequelize');
const { sequelize } = require('../database/connection');

const Payslip = sequelize.define('Payslip', {
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
  month: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  year: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  pay_period_start: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  pay_period_end: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  basic_salary: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  allowances: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
    defaultValue: 0,
  },
  allowance_breakdown: {
    type: DataTypes.JSONB,
    allowNull: false,
    defaultValue: {},
  },
  deductions: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
    defaultValue: 0,
  },
  deduction_breakdown: {
    type: DataTypes.JSONB,
    allowNull: false,
    defaultValue: {},
  },
  overtime: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
    defaultValue: 0,
  },
  bonus: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
    defaultValue: 0,
  },
  gross_salary: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  net_salary: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  currency: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'USD',
  },
  status: {
    type: DataTypes.ENUM('draft', 'processed', 'paid'),
    allowNull: false,
    defaultValue: 'draft',
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  generated_by: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id',
    },
    onDelete: 'SET NULL',
  },
  generated_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  finalized_by: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id',
    },
    onDelete: 'SET NULL',
  },
  finalized_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'payslips',
  indexes: [
    {
      fields: ['organization_id', 'employee_id'],
      name: 'payslips_org_employee',
    },
    {
      fields: ['employee_id', 'year', 'month'],
      unique: true,
      name: 'unique_payslip_per_month',
    },
    {
      fields: ['status'],
    },
  ],
});

module.exports = Payslip;
