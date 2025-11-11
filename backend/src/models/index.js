const { sequelize } = require('../database/connection');
const Organization = require('./Organization');
const User = require('./User');
const Employee = require('./Employee');
const Department = require('./Department');
const Payslip = require('./Payslip');
const LeaveRequest = require('./LeaveRequest');
// Note: These models will be created next
// const Attendance = require('./Attendance');
// const Task = require('./Task');
// const Payslip = require('./Payslip');

// Define basic associations
function defineAssociations() {
  // Organization associations
  Organization.hasMany(User, {
    foreignKey: 'organization_id',
    as: 'users',
    onDelete: 'CASCADE',
  });

  Organization.hasMany(Employee, {
    foreignKey: 'organization_id',
    as: 'employees',
    onDelete: 'CASCADE',
  });

  // User associations
  User.belongsTo(Organization, {
    foreignKey: 'organization_id',
    as: 'organization',
  });

  User.hasOne(Employee, {
    foreignKey: 'user_id',
    as: 'employeeProfile',
  });

  // Employee associations
  Employee.belongsTo(Organization, {
    foreignKey: 'organization_id',
    as: 'organization',
  });

  Employee.belongsTo(User, {
    foreignKey: 'user_id',
    as: 'user',
  });

  Employee.belongsTo(Employee, {
    foreignKey: 'manager_id',
    as: 'manager',
  });

  Employee.hasMany(Employee, {
    foreignKey: 'manager_id',
    as: 'subordinates',
  });

  // Department associations
  Organization.hasMany(Department, {
    foreignKey: 'organization_id',
    as: 'departments',
    onDelete: 'CASCADE',
  });

  Department.belongsTo(Organization, {
    foreignKey: 'organization_id',
    as: 'organization',
  });

  Department.belongsTo(Employee, {
    foreignKey: 'manager_id',
    as: 'manager',
  });

  Employee.hasMany(Department, {
    foreignKey: 'manager_id',
    as: 'managedDepartments',
  });

  // Payslip associations
  Organization.hasMany(Payslip, {
    foreignKey: 'organization_id',
    as: 'payslips',
    onDelete: 'CASCADE',
  });

  Payslip.belongsTo(Organization, {
    foreignKey: 'organization_id',
    as: 'organization',
  });

  Employee.hasMany(Payslip, {
    foreignKey: 'employee_id',
    as: 'payslips',
    onDelete: 'CASCADE',
  });

  Payslip.belongsTo(Employee, {
    foreignKey: 'employee_id',
    as: 'employee',
  });

  Payslip.belongsTo(User, {
    foreignKey: 'generated_by',
    as: 'generatedBy',
  });

  Payslip.belongsTo(User, {
    foreignKey: 'finalized_by',
    as: 'finalizedBy',
  });

  // Leave request associations
  Organization.hasMany(LeaveRequest, {
    foreignKey: 'organization_id',
    as: 'leaveRequests',
    onDelete: 'CASCADE',
  });

  LeaveRequest.belongsTo(Organization, {
    foreignKey: 'organization_id',
    as: 'organization',
  });

  Employee.hasMany(LeaveRequest, {
    foreignKey: 'employee_id',
    as: 'leaveRequests',
    onDelete: 'CASCADE',
  });

  LeaveRequest.belongsTo(Employee, {
    foreignKey: 'employee_id',
    as: 'employee',
  });

  LeaveRequest.belongsTo(User, {
    foreignKey: 'requested_by',
    as: 'requestedBy',
  });

  LeaveRequest.belongsTo(User, {
    foreignKey: 'approved_by',
    as: 'approvedBy',
  });
}

// Initialize associations
defineAssociations();

module.exports = {
  sequelize,
  Organization,
  User,
  Employee,
  Department,
  Payslip,
  LeaveRequest,
  // Additional models will be added as we create them
};
