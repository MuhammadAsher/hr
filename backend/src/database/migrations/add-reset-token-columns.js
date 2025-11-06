/**
 * Migration script to add reset_token and reset_token_expiry columns to users table
 * Run this script to update the database schema:
 * node backend/src/database/migrations/add-reset-token-columns.js
 */

const { sequelize } = require('../connection');
const { User } = require('../../models');

async function addResetTokenColumns() {
  try {
    console.log('🔄 Adding reset_token columns to users table...');

    // Check if columns already exist
    const [results] = await sequelize.query(`
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name='users'
    `);

    if (results.length === 0) {
      console.log('❌ Users table does not exist. Please run database initialization first.');
      process.exit(1);
    }

    // Get table info to check if columns exist
    const [columns] = await sequelize.query(`PRAGMA table_info(users)`);
    const columnNames = columns.map(col => col.name);
    
    const hasResetToken = columnNames.includes('reset_token');
    const hasResetTokenExpiry = columnNames.includes('reset_token_expiry');

    if (hasResetToken && hasResetTokenExpiry) {
      console.log('✅ Reset token columns already exist.');
      process.exit(0);
    }

    // Add columns if they don't exist
    if (!hasResetToken) {
      await sequelize.query(`
        ALTER TABLE users 
        ADD COLUMN reset_token TEXT
      `);
      console.log('✅ Added reset_token column');
    }

    if (!hasResetTokenExpiry) {
      await sequelize.query(`
        ALTER TABLE users 
        ADD COLUMN reset_token_expiry DATETIME
      `);
      console.log('✅ Added reset_token_expiry column');
    }

    console.log('✅ Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

// Run migration
addResetTokenColumns();

