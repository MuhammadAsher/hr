const { sequelize } = require('../database/connection');
const Organization = require('./Organization');
const User = require('./User');
const Employee = require('./Employee');
// Note: These models will be created next
// const Department = require('./Department');
// const LeaveRequest = require('./LeaveRequest');
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
}

// Initialize associations
defineAssociations();

module.exports = {
  sequelize,
  Organization,
  User,
  Employee,
  // Additional models will be added as we create them
};
