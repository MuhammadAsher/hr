/**
 * Script to create an admin user
 * Usage: node create-admin-user.js
 */

const { sequelize } = require('./src/database/connection');
const { User, Organization } = require('./src/models');

async function createAdminUser() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connection established.');

    const email = 'asheradmin@gmail.com';
    const password = 'asheradmin';
    const name = 'Asher Admin';
    const role = 'admin';

    // Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      console.log(`⚠️ User with email ${email} already exists.`);
      console.log('Updating password...');
      existingUser.password_hash = password; // Will be hashed by beforeUpdate hook
      await existingUser.save();
      console.log('✅ Password updated successfully.');
      process.exit(0);
    }

    // Get or create an organization (we need one for the admin)
    let organization = await Organization.findOne();
    if (!organization) {
      // Create a default organization if none exists
      organization = await Organization.create({
        name: 'Default Organization',
        email: 'admin@org.com',
        industry: 'Technology',
        subscription_plan: 'Free',
        employee_limit: 10,
      });
      console.log('✅ Created default organization.');
    } else {
      console.log(`✅ Using existing organization: ${organization.name}`);
    }

    // Create admin user
    const user = await User.create({
      organization_id: organization.id,
      email,
      password_hash: password, // Will be hashed by beforeCreate hook
      name,
      role,
      is_active: true,
      email_verified: true,
    });

    console.log('✅ Admin user created successfully!');
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${password}`);
    console.log(`   Role: ${role}`);
    console.log(`   Organization: ${organization.name}`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating admin user:', error);
    process.exit(1);
  }
}

createAdminUser();

