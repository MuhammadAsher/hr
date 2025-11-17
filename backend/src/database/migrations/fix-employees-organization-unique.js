const { sequelize } = require('../../database/connection');

async function fixEmployeesOrganizationUnique() {
  try {
    console.log('🔧 Fixing organization_id UNIQUE constraint in employees table...');
    
    // SQLite doesn't support DROP CONSTRAINT directly, so we need to recreate the table
    // First, disable foreign key checks temporarily
    await sequelize.query(`PRAGMA foreign_keys = OFF`);
    
    // Step 1: Create new table without the UNIQUE on organization_id
    await sequelize.query(`
      CREATE TABLE employees_new (
        id UUID UNIQUE PRIMARY KEY,
        organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        employee_id VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL,
        phone VARCHAR(255),
        department VARCHAR(255) NOT NULL,
        position VARCHAR(255) NOT NULL,
        join_date DATETIME NOT NULL,
        salary DECIMAL(10,2) NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        address TEXT,
        emergency_contact JSONB DEFAULT '{}',
        date_of_birth DATETIME,
        hire_date DATETIME,
        termination_date DATETIME,
        manager_id UUID REFERENCES employees(id),
        profile_picture VARCHAR(255),
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL
      )
    `);
    
    // Step 2: Copy data from old table to new table
    await sequelize.query(`
      INSERT INTO employees_new 
      SELECT * FROM employees
    `);
    
    // Step 3: Drop old table
    await sequelize.query(`DROP TABLE employees`);
    
    // Step 4: Rename new table to employees
    await sequelize.query(`ALTER TABLE employees_new RENAME TO employees`);
    
    // Step 5: Recreate indexes (without UNIQUE on organization_id)
    await sequelize.query(`
      CREATE INDEX IF NOT EXISTS employees_organization_id ON employees (organization_id)
    `);
    
    await sequelize.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS unique_employee_id_per_organization ON employees (employee_id, organization_id)
    `);
    
    await sequelize.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS unique_employee_email_per_organization ON employees (email, organization_id)
    `);
    
    await sequelize.query(`
      CREATE INDEX IF NOT EXISTS employees_department ON employees (department)
    `);
    
    await sequelize.query(`
      CREATE INDEX IF NOT EXISTS employees_status ON employees (status)
    `);
    
    await sequelize.query(`
      CREATE INDEX IF NOT EXISTS employees_manager_id ON employees (manager_id)
    `);
    
    // Re-enable foreign key checks
    await sequelize.query(`PRAGMA foreign_keys = ON`);
    
    console.log('✅ Successfully fixed organization_id UNIQUE constraint!');
    console.log('   - Removed UNIQUE constraint on organization_id');
    console.log('   - Kept composite UNIQUE indexes (employee_id, organization_id) and (email, organization_id)');
    
  } catch (error) {
    // Re-enable foreign key checks even on error
    await sequelize.query(`PRAGMA foreign_keys = ON`).catch(() => {});
    console.error('❌ Error fixing organization_id UNIQUE constraint:', error);
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  fixEmployeesOrganizationUnique()
    .then(() => {
      console.log('Migration completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration failed:', error);
      process.exit(1);
    });
}

module.exports = fixEmployeesOrganizationUnique;

