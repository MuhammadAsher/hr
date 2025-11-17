const { sequelize } = require('../../database/connection');

async function fixEmailUniqueConstraint() {
  try {
    console.log('🔧 Fixing email unique constraint in users table...');
    
    // SQLite doesn't support DROP CONSTRAINT directly, so we need to recreate the table
    // First, disable foreign key checks temporarily
    await sequelize.query(`PRAGMA foreign_keys = OFF`);
    
    // Step 1: Create new table without the global UNIQUE on email
    await sequelize.query(`
      CREATE TABLE users_new (
        id UUID UNIQUE PRIMARY KEY,
        organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
        email VARCHAR(255) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        role TEXT NOT NULL DEFAULT 'employee',
        is_super_admin TINYINT(1) NOT NULL DEFAULT 0,
        is_active TINYINT(1) NOT NULL DEFAULT 1,
        last_login DATETIME,
        email_verified TINYINT(1) NOT NULL DEFAULT 0,
        profile_picture VARCHAR(255),
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        reset_token VARCHAR(255),
        reset_token_expiry DATETIME
      )
    `);
    
    // Step 2: Copy data from old table to new table
    await sequelize.query(`
      INSERT INTO users_new 
      SELECT * FROM users
    `);
    
    // Step 3: Drop old table
    await sequelize.query(`DROP TABLE users`);
    
    // Step 4: Rename new table to users
    await sequelize.query(`ALTER TABLE users_new RENAME TO users`);
    
    // Step 5: Recreate indexes
    await sequelize.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS unique_email_per_organization ON users (email, organization_id)
    `);
    
    await sequelize.query(`
      CREATE INDEX IF NOT EXISTS users_organization_id ON users (organization_id)
    `);
    
    await sequelize.query(`
      CREATE INDEX IF NOT EXISTS users_role ON users (role)
    `);
    
    await sequelize.query(`
      CREATE INDEX IF NOT EXISTS users_is_active ON users (is_active)
    `);
    
    // Re-enable foreign key checks
    await sequelize.query(`PRAGMA foreign_keys = ON`);
    
    console.log('✅ Successfully fixed email unique constraint!');
    console.log('   - Removed global UNIQUE constraint on email');
    console.log('   - Kept composite UNIQUE index (email, organization_id)');
    
  } catch (error) {
    // Re-enable foreign key checks even on error
    await sequelize.query(`PRAGMA foreign_keys = ON`).catch(() => {});
    console.error('❌ Error fixing email unique constraint:', error);
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  fixEmailUniqueConstraint()
    .then(() => {
      console.log('Migration completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration failed:', error);
      process.exit(1);
    });
}

module.exports = fixEmailUniqueConstraint;

