#!/usr/bin/env node

/**
 * Script to create a new admin user
 * Usage: node create-user.js <email> <password> <name> [organizationId]
 * 
 * Example:
 *   node create-user.js asheradmin@gmail.com asheradmin "Asher Admin" 
 */

const { User, Organization } = require('./src/models');
const { sequelize } = require('./src/database/connection');

async function createUser() {
  const args = process.argv.slice(2);
  
  if (args.length < 3) {
    console.log('Usage: node create-user.js <email> <password> <name> [organizationId]');
    console.log('');
    console.log('Examples:');
    console.log('  # Create admin user for existing organization');
    console.log('  node create-user.js admin@example.com password123 "Admin Name" <organization-id>');
    console.log('');
    console.log('  # Create admin user (will use first available organization)');
    console.log('  node create-user.js admin@example.com password123 "Admin Name"');
    process.exit(1);
  }

  const [email, password, name, organizationId] = args;

  try {
    // Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connection established.');

    // Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      console.log(`❌ User with email ${email} already exists!`);
      process.exit(1);
    }

    let orgId = organizationId;
    let isSuperAdmin = false;

    // If no organization ID provided, check if we should create super admin or use first org
    if (!orgId) {
      // Check if this should be a super admin (check env or if it's a specific email pattern)
      if (email.includes('superadmin') || email.includes('platform')) {
        isSuperAdmin = true;
        orgId = null;
        console.log('ℹ️  Creating as Super Admin (no organization)');
      } else {
        // Find first active organization
        const org = await Organization.findOne({
          where: { is_active: true },
          order: [['created_at', 'ASC']],
        });

        if (!org) {
          console.log('❌ No active organization found. Please provide organization ID or create an organization first.');
          console.log('   You can run: node setup.js init');
          process.exit(1);
        }

        orgId = org.id;
        console.log(`ℹ️  Using organization: ${org.name} (${org.id})`);
      }
    } else {
      // Verify organization exists
      const org = await Organization.findByPk(orgId);
      if (!org) {
        console.log(`❌ Organization with ID ${orgId} not found!`);
        process.exit(1);
      }
      if (!org.is_active) {
        console.log(`⚠️  Warning: Organization ${org.name} is not active!`);
      }
    }

    // Create user
    const user = await User.create({
      email,
      password_hash: password, // Will be hashed by beforeCreate hook
      name,
      role: 'admin',
      is_super_admin: isSuperAdmin,
      organization_id: orgId,
      email_verified: true,
      is_active: true,
    });

    console.log('✅ User created successfully!');
    console.log('');
    console.log('User Details:');
    console.log(`  Email: ${user.email}`);
    console.log(`  Name: ${user.name}`);
    console.log(`  Role: ${user.role}`);
    console.log(`  Super Admin: ${user.is_super_admin ? 'Yes' : 'No'}`);
    console.log(`  Organization ID: ${user.organization_id || 'N/A (Super Admin)'}`);
    console.log('');
    console.log('You can now login with these credentials.');

    await sequelize.close();
  } catch (error) {
    console.error('❌ Error creating user:', error.message);
    process.exit(1);
  }
}

createUser();

