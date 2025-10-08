#!/usr/bin/env node

/**
 * Database Viewer Script
 * Run this script to view all your backend database data in a formatted way
 * Usage: node view-database.js
 */

const { sequelize, User, Organization, Employee } = require('./src/models');

async function viewDatabase() {
  try {
    console.log('🗄️  HR Platform Database Viewer');
    console.log('================================\n');

    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connection established.\n');

    // View Organizations
    console.log('🏢 ORGANIZATIONS:');
    console.log('================');
    const organizations = await Organization.findAll({
      attributes: ['id', 'name', 'email', 'industry', 'subscription_plan', 'is_active', 'employee_limit']
    });
    
    if (organizations.length === 0) {
      console.log('No organizations found.\n');
    } else {
      organizations.forEach((org, index) => {
        console.log(`${index + 1}. ${org.name}`);
        console.log(`   Email: ${org.email}`);
        console.log(`   Industry: ${org.industry}`);
        console.log(`   Plan: ${org.subscription_plan}`);
        console.log(`   Active: ${org.is_active ? 'Yes' : 'No'}`);
        console.log(`   Employee Limit: ${org.employee_limit}`);
        console.log(`   ID: ${org.id}\n`);
      });
    }

    // View Users
    console.log('👥 USERS:');
    console.log('=========');
    const users = await User.findAll({
      include: [{
        model: Organization,
        as: 'organization',
        attributes: ['name']
      }],
      attributes: ['id', 'email', 'name', 'role', 'is_super_admin', 'is_active', 'last_login', 'created_at']
    });

    if (users.length === 0) {
      console.log('No users found.\n');
    } else {
      users.forEach((user, index) => {
        console.log(`${index + 1}. ${user.name} (${user.email})`);
        console.log(`   Role: ${user.role}`);
        console.log(`   Super Admin: ${user.is_super_admin ? 'Yes' : 'No'}`);
        console.log(`   Active: ${user.is_active ? 'Yes' : 'No'}`);
        console.log(`   Organization: ${user.organization ? user.organization.name : 'None'}`);
        console.log(`   Last Login: ${user.last_login || 'Never'}`);
        console.log(`   Created: ${user.created_at}`);
        console.log(`   ID: ${user.id}\n`);
      });
    }

    // View Employees
    console.log('👨‍💼 EMPLOYEES:');
    console.log('=============');
    const employees = await Employee.findAll({
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['email', 'last_login']
        },
        {
          model: Employee,
          as: 'manager',
          attributes: ['name', 'position']
        }
      ],
      attributes: ['id', 'employee_id', 'name', 'email', 'department', 'position', 'salary', 'status', 'join_date']
    });

    if (employees.length === 0) {
      console.log('No employees found.\n');
    } else {
      employees.forEach((emp, index) => {
        console.log(`${index + 1}. ${emp.name} (${emp.employee_id})`);
        console.log(`   Email: ${emp.email}`);
        console.log(`   Department: ${emp.department}`);
        console.log(`   Position: ${emp.position}`);
        console.log(`   Salary: $${emp.salary}`);
        console.log(`   Status: ${emp.status}`);
        console.log(`   Join Date: ${emp.join_date}`);
        console.log(`   Manager: ${emp.manager ? emp.manager.name : 'None'}`);
        console.log(`   User Account: ${emp.user ? emp.user.email : 'None'}`);
        console.log(`   ID: ${emp.id}\n`);
      });
    }

    // Database Statistics
    console.log('📊 DATABASE STATISTICS:');
    console.log('=======================');
    console.log(`Total Organizations: ${organizations.length}`);
    console.log(`Total Users: ${users.length}`);
    console.log(`Total Employees: ${employees.length}`);
    console.log(`Active Users: ${users.filter(u => u.is_active).length}`);
    console.log(`Super Admins: ${users.filter(u => u.is_super_admin).length}`);
    console.log(`Active Employees: ${employees.filter(e => e.status === 'active').length}\n`);

    console.log('✅ Database view completed!');

  } catch (error) {
    console.error('❌ Error viewing database:', error.message);
  } finally {
    await sequelize.close();
  }
}

// Run the viewer
viewDatabase();
