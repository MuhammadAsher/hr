/**
 * Migration script to create departments table
 * Run this script to create the departments table:
 * node backend/src/database/migrations/create-departments-table.js
 */

const { sequelize } = require('../connection');
const { Department } = require('../../models');

async function createDepartmentsTable() {
  try {
    console.log('🔄 Creating departments table...');

    // Check if table already exists
    const [results] = await sequelize.query(`
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name='departments'
    `);

    if (results.length > 0) {
      console.log('✅ Departments table already exists.');
      process.exit(0);
    }

    // Temporarily disable foreign keys
    await sequelize.query('PRAGMA foreign_keys = OFF;');

    // Create the table by syncing the model
    await Department.sync({ force: false });

    // Re-enable foreign keys
    await sequelize.query('PRAGMA foreign_keys = ON;');

    console.log('✅ Departments table created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    console.error('Error stack:', error.stack);
    process.exit(1);
  }
}

// Run migration
createDepartmentsTable();

