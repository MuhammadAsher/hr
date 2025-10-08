const { sequelize } = require('./connection');
const { Organization, User } = require('../models');

async function initializeDatabase() {
  try {
    console.log('🔄 Initializing database...');

    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connection established.');

    // Temporarily disable foreign key constraints for SQLite
    await sequelize.query('PRAGMA foreign_keys = OFF;');

    // Sync models (create tables)
    await sequelize.sync({ force: false, alter: true });

    // Re-enable foreign key constraints
    await sequelize.query('PRAGMA foreign_keys = ON;');

    console.log('✅ Database models synchronized.');

    // Create super admin if it doesn't exist
    await createSuperAdmin();

    // Create sample organization for testing
    await createSampleOrganization();

    console.log('✅ Database initialization completed.');
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    throw error;
  }
}

async function createSuperAdmin() {
  try {
    const superAdminEmail = process.env.SUPER_ADMIN_EMAIL || 'superadmin@hrplatform.com';
    const superAdminPassword = process.env.SUPER_ADMIN_PASSWORD || 'super123';
    const superAdminName = process.env.SUPER_ADMIN_NAME || 'Platform Administrator';

    // Check if super admin already exists
    const existingSuperAdmin = await User.findOne({
      where: {
        email: superAdminEmail,
        is_super_admin: true,
      },
    });

    if (existingSuperAdmin) {
      console.log('ℹ️  Super admin already exists.');
      return;
    }

    // Create super admin
    const superAdmin = await User.create({
      email: superAdminEmail,
      password_hash: superAdminPassword,
      name: superAdminName,
      role: 'admin',
      is_super_admin: true,
      organization_id: null,
      email_verified: true,
    });

    console.log('✅ Super admin created:', superAdmin.email);
  } catch (error) {
    console.error('❌ Failed to create super admin:', error);
    throw error;
  }
}

async function createSampleOrganization() {
  try {
    // Check if sample organization already exists
    let organization = await Organization.findOne({
      where: { email: 'admin@techsolutions.com' },
    });

    if (organization) {
      console.log('ℹ️  Sample organization already exists.');
    } else {
      // Create sample organization
      organization = await Organization.create({
      name: 'Tech Solutions Inc.',
      email: 'admin@techsolutions.com',
      phone: '+1-555-0101',
      address: '123 Tech Street, Silicon Valley, CA 94025',
      industry: 'Technology',
      subscription_plan: 'Premium',
      employee_limit: 200,
      tax_id: 'TAX-001-2023',
      website: 'https://techsolutions.com',
      settings: {
        workingHours: '9:00 AM - 5:00 PM',
        workingDays: 'Monday - Friday',
        currency: 'USD',
        dateFormat: 'MM/DD/YYYY',
        timeZone: 'PST',
      },
    });

      console.log('✅ Sample organization created:', organization.name);
    }

    // Check if admin user already exists
    let adminUser = await User.findOne({
      where: { email: 'admin@hr.com', organization_id: organization.id },
    });

    if (!adminUser) {
      // Create admin user for the organization
      adminUser = await User.create({
      organization_id: organization.id,
      email: 'admin@hr.com',
      password_hash: 'admin123',
      name: 'Admin User',
      role: 'admin',
      email_verified: true,
    });

      console.log('✅ Sample admin user created:', adminUser.email);
    } else {
      console.log('ℹ️  Sample admin user already exists.');
    }

    // Update organization with admin ID if not set
    if (!organization.admin_id) {
      await organization.update({ admin_id: adminUser.id });
    }

    // Check if employee user already exists
    let employeeUser = await User.findOne({
      where: { email: 'employee@hr.com', organization_id: organization.id },
    });

    if (!employeeUser) {
      // Create sample employee user
      employeeUser = await User.create({
      organization_id: organization.id,
      email: 'employee@hr.com',
      password_hash: 'employee123',
      name: 'John Employee',
      role: 'employee',
      email_verified: true,
    });

      console.log('✅ Sample employee user created:', employeeUser.email);
    } else {
      console.log('ℹ️  Sample employee user already exists.');
    }
  } catch (error) {
    console.error('❌ Failed to create sample organization:', error);
    throw error;
  }
}

async function resetDatabase() {
  try {
    console.log('🔄 Resetting database...');

    // Temporarily disable foreign key constraints for SQLite
    await sequelize.query('PRAGMA foreign_keys = OFF;');

    await sequelize.sync({ force: true });

    // Re-enable foreign key constraints
    await sequelize.query('PRAGMA foreign_keys = ON;');

    console.log('✅ Database reset completed.');

    await createSuperAdmin();
    await createSampleOrganization();

    console.log('✅ Database reinitialized.');
  } catch (error) {
    console.error('❌ Database reset failed:', error);
    throw error;
  }
}

module.exports = {
  initializeDatabase,
  resetDatabase,
  createSuperAdmin,
  createSampleOrganization,
};
