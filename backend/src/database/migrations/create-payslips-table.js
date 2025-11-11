module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('payslips', {
      id: {
        type: Sequelize.UUID,
        primaryKey: true,
        defaultValue: Sequelize.UUIDV4,
      },
      organization_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'organizations',
          key: 'id',
        },
        onDelete: 'CASCADE',
      },
      employee_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'employees',
          key: 'id',
        },
        onDelete: 'CASCADE',
      },
      month: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      year: {
        type: Sequelize.INTEGER,
        allowNull: false,
      },
      pay_period_start: {
        type: Sequelize.DATEONLY,
        allowNull: false,
      },
      pay_period_end: {
        type: Sequelize.DATEONLY,
        allowNull: false,
      },
      basic_salary: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
      },
      allowances: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0,
      },
      allowance_breakdown: {
        type: Sequelize.JSON,
        allowNull: false,
        defaultValue: {},
      },
      deductions: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0,
      },
      deduction_breakdown: {
        type: Sequelize.JSON,
        allowNull: false,
        defaultValue: {},
      },
      overtime: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0,
      },
      bonus: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0,
      },
      gross_salary: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
      },
      net_salary: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
      },
      currency: {
        type: Sequelize.STRING,
        allowNull: false,
        defaultValue: 'USD',
      },
      status: {
        type: Sequelize.ENUM('draft', 'processed', 'paid'),
        allowNull: false,
        defaultValue: 'draft',
      },
      notes: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      generated_by: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id',
        },
        onDelete: 'SET NULL',
      },
      generated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      finalized_by: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id',
        },
        onDelete: 'SET NULL',
      },
      finalized_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
    });

    await queryInterface.addIndex('payslips', ['organization_id', 'employee_id'], {
      name: 'payslips_org_employee',
    });

    await queryInterface.addIndex('payslips', ['employee_id', 'year', 'month'], {
      name: 'unique_payslip_per_month',
      unique: true,
    });

    await queryInterface.addIndex('payslips', ['status'], {
      name: 'payslips_status_idx',
    });
  },

  down: async (queryInterface) => {
    await queryInterface.removeIndex('payslips', 'payslips_org_employee');
    await queryInterface.removeIndex('payslips', 'unique_payslip_per_month');
    await queryInterface.removeIndex('payslips', 'payslips_status_idx');
    await queryInterface.dropTable('payslips');
  },
};
