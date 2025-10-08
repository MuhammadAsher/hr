#!/usr/bin/env node

const { initializeDatabase, resetDatabase } = require('./src/database/init');

async function setup() {
  const args = process.argv.slice(2);
  const command = args[0];

  try {
    switch (command) {
      case 'init':
        console.log('🚀 Initializing HR Platform API database...');
        await initializeDatabase();
        console.log('✅ Setup completed successfully!');
        console.log('\n📋 Default login credentials:');
        console.log('Super Admin: superadmin@hrplatform.com / super123');
        console.log('Org Admin: admin@hr.com / admin123');
        console.log('Employee: employee@hr.com / employee123');
        console.log('\n🌐 Start the server with: npm run dev');
        break;

      case 'reset':
        console.log('⚠️  Resetting database (this will delete all data)...');
        await resetDatabase();
        console.log('✅ Database reset completed!');
        break;

      default:
        console.log('HR Platform API Setup');
        console.log('');
        console.log('Usage:');
        console.log('  node setup.js init   - Initialize database with sample data');
        console.log('  node setup.js reset  - Reset database (WARNING: deletes all data)');
        console.log('');
        console.log('Make sure to configure your .env file before running setup.');
        break;
    }
  } catch (error) {
    console.error('❌ Setup failed:', error.message);
    process.exit(1);
  }
}

setup();
