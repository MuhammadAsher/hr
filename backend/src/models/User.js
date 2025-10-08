const { DataTypes } = require('sequelize');
const bcrypt = require('bcryptjs');
const { sequelize } = require('../database/connection');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  organization_id: {
    type: DataTypes.UUID,
    allowNull: true, // Super admin doesn't belong to any organization
    references: {
      model: 'organizations',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      isEmail: true,
    },
  },
  password_hash: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      len: [6, 255],
    },
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [2, 255],
    },
  },
  role: {
    type: DataTypes.ENUM('admin', 'employee'),
    allowNull: false,
    defaultValue: 'employee',
  },
  is_super_admin: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  last_login: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  email_verified: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  profile_picture: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'users',
  indexes: [
    {
      fields: ['email', 'organization_id'],
      unique: true,
      name: 'unique_email_per_organization',
    },
    {
      fields: ['organization_id'],
    },
    {
      fields: ['role'],
    },
    {
      fields: ['is_active'],
    },
  ],
  hooks: {
    beforeCreate: async (user) => {
      if (user.password_hash) {
        user.password_hash = await bcrypt.hash(user.password_hash, 12);
      }
    },
    beforeUpdate: async (user) => {
      if (user.changed('password_hash')) {
        user.password_hash = await bcrypt.hash(user.password_hash, 12);
      }
    },
  },
});

// Instance methods
User.prototype.validatePassword = async function(password) {
  return bcrypt.compare(password, this.password_hash);
};

User.prototype.toJSON = function() {
  const values = { ...this.get() };
  delete values.password_hash;
  return values;
};

User.prototype.updateLastLogin = async function() {
  this.last_login = new Date();
  await this.save();
};

// Class methods
User.findByEmail = async function(email, organizationId = null) {
  const whereClause = { email, is_active: true };
  
  if (organizationId) {
    whereClause.organization_id = organizationId;
  }
  
  return this.findOne({ where: whereClause });
};

User.createSuperAdmin = async function(email, password, name) {
  return this.create({
    email,
    password_hash: password,
    name,
    role: 'admin',
    is_super_admin: true,
    organization_id: null,
    email_verified: true,
  });
};

module.exports = User;
