# 🚀 API Implementation Guide

## Complete Guide to Implementing Production Backend

This guide will help you implement a production-ready backend API for the HR Management SaaS Platform.

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Technology Stack](#technology-stack)
3. [Database Schema](#database-schema)
4. [Authentication & Security](#authentication--security)
5. [API Endpoints](#api-endpoints)
6. [Deployment](#deployment)
7. [Testing](#testing)

---

## 🎯 Quick Start

### View API Documentation

**Option 1: Online Swagger UI**
1. Open `api/index.html` in a web browser
2. The Swagger UI will load with interactive API documentation
3. You can test endpoints directly from the browser

**Option 2: Use Postman**
1. Import `api/postman_collection.json` into Postman
2. Set the `base_url` variable to your API endpoint
3. Login to get JWT token (automatically saved)
4. Test all endpoints

**Option 3: View OpenAPI Spec**
- Open `api/openapi.yaml` in any OpenAPI-compatible tool
- Use Swagger Editor: https://editor.swagger.io/
- Paste the YAML content to view documentation

---

## 🛠️ Technology Stack

### Recommended Backend Stack

#### Option 1: Node.js + Express
```bash
# Dependencies
npm install express
npm install jsonwebtoken bcrypt
npm install pg sequelize  # PostgreSQL
npm install cors helmet express-rate-limit
npm install dotenv
npm install swagger-ui-express
```

#### Option 2: Python + FastAPI
```bash
# Dependencies
pip install fastapi uvicorn
pip install sqlalchemy psycopg2-binary
pip install python-jose[cryptography] passlib[bcrypt]
pip install python-multipart
pip install pydantic-settings
```

#### Option 3: Go + Gin
```bash
# Dependencies
go get -u github.com/gin-gonic/gin
go get -u github.com/golang-jwt/jwt/v5
go get -u gorm.io/gorm
go get -u gorm.io/driver/postgres
```

---

## 🗄️ Database Schema

### PostgreSQL Schema (Recommended)

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Organizations table
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    industry VARCHAR(100),
    logo VARCHAR(500),
    registered_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subscription_plan VARCHAR(50) DEFAULT 'Free',
    is_active BOOLEAN DEFAULT true,
    employee_limit INTEGER DEFAULT 10,
    settings JSONB DEFAULT '{}',
    admin_id UUID,
    tax_id VARCHAR(100),
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'employee')),
    is_super_admin BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, email)
);

-- Employees table
CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    department VARCHAR(100),
    position VARCHAR(100),
    join_date DATE,
    salary DECIMAL(12, 2),
    status VARCHAR(50) DEFAULT 'active',
    address TEXT,
    emergency_contact JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, email)
);

-- Departments table
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    manager_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    budget DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, name)
);

-- Leave requests table
CREATE TABLE leave_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
    leave_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days INTEGER NOT NULL,
    reason TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP,
    review_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attendance table
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    check_in TIMESTAMP,
    check_out TIMESTAMP,
    status VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, employee_id, date)
);

-- Tasks table
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    priority VARCHAR(50),
    due_date DATE,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payslips table
CREATE TABLE payslips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    basic_salary DECIMAL(12, 2),
    allowances JSONB DEFAULT '{}',
    deductions JSONB DEFAULT '{}',
    gross_salary DECIMAL(12, 2),
    net_salary DECIMAL(12, 2),
    payment_date DATE,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, employee_id, month, year)
);

-- Indexes for performance
CREATE INDEX idx_users_org ON users(organization_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_employees_org ON employees(organization_id);
CREATE INDEX idx_employees_dept ON employees(department);
CREATE INDEX idx_leave_requests_org ON leave_requests(organization_id);
CREATE INDEX idx_leave_requests_status ON leave_requests(status);
CREATE INDEX idx_attendance_org_date ON attendance(organization_id, date);
CREATE INDEX idx_tasks_org_employee ON tasks(organization_id, employee_id);
CREATE INDEX idx_payslips_org_employee ON payslips(organization_id, employee_id);

-- Row Level Security (RLS) for multi-tenancy
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE payslips ENABLE ROW LEVEL SECURITY;

-- RLS Policies (example for employees table)
CREATE POLICY org_isolation_policy ON employees
    USING (organization_id = current_setting('app.current_organization_id')::UUID);
```

---

## 🔐 Authentication & Security

### JWT Implementation

#### Token Structure
```json
{
  "userId": "uuid",
  "email": "user@example.com",
  "organizationId": "uuid",
  "role": "admin",
  "isSuperAdmin": false,
  "iat": 1234567890,
  "exp": 1234654290
}
```

#### Node.js Example
```javascript
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

// Generate JWT token
function generateToken(user) {
  return jwt.sign(
    {
      userId: user.id,
      email: user.email,
      organizationId: user.organizationId,
      role: user.role,
      isSuperAdmin: user.isSuperAdmin
    },
    process.env.JWT_SECRET,
    { expiresIn: '24h' }
  );
}

// Verify JWT token
function verifyToken(token) {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid token');
  }
}

// Hash password
async function hashPassword(password) {
  return await bcrypt.hash(password, 10);
}

// Verify password
async function verifyPassword(password, hash) {
  return await bcrypt.compare(password, hash);
}
```

#### Middleware for Authentication
```javascript
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const user = verifyToken(token);
    req.user = user;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
}
```

#### Middleware for Organization Isolation
```javascript
function enforceOrganizationContext(req, res, next) {
  // Set organization context for database queries
  const organizationId = req.user.organizationId;
  
  // For PostgreSQL with RLS
  req.db.query(
    `SET LOCAL app.current_organization_id = '${organizationId}'`
  );
  
  next();
}
```

---

## 📡 API Endpoints Implementation

### Example: Login Endpoint (Node.js + Express)

```javascript
const express = require('express');
const router = express.Router();

router.post('/auth/login', async (req, res) => {
  try {
    const { email, password, role } = req.body;

    // Validate input
    if (!email || !password || !role) {
      return res.status(400).json({
        error: 'Missing required fields',
        message: 'Email, password, and role are required'
      });
    }

    // Find user
    const user = await db.users.findOne({
      where: { email, role, isActive: true },
      include: [{ model: db.organizations }]
    });

    if (!user) {
      return res.status(401).json({
        error: 'Invalid credentials',
        message: 'Email or password is incorrect'
      });
    }

    // Verify password
    const isValidPassword = await verifyPassword(password, user.passwordHash);
    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Invalid credentials',
        message: 'Email or password is incorrect'
      });
    }

    // Check if organization is active
    if (!user.organization.isActive) {
      return res.status(403).json({
        error: 'Organization inactive',
        message: 'Your organization account is currently inactive'
      });
    }

    // Generate JWT token
    const token = generateToken(user);

    // Update last login
    await user.update({ lastLogin: new Date() });

    // Return response
    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        organizationId: user.organizationId,
        isSuperAdmin: user.isSuperAdmin
      },
      expiresIn: 86400 // 24 hours
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'An error occurred during login'
    });
  }
});

module.exports = router;
```

### Example: Get Employees Endpoint

```javascript
router.get('/employees', authenticateToken, enforceOrganizationContext, async (req, res) => {
  try {
    const { page = 1, limit = 20, department, status } = req.query;
    const organizationId = req.user.organizationId;

    // Build query
    const where = { organizationId };
    if (department) where.department = department;
    if (status) where.status = status;

    // Get employees with pagination
    const { count, rows } = await db.employees.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: (parseInt(page) - 1) * parseInt(limit),
      order: [['createdAt', 'DESC']]
    });

    res.json({
      data: rows,
      total: count,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages: Math.ceil(count / limit)
    });

  } catch (error) {
    console.error('Get employees error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to retrieve employees'
    });
  }
});
```

---

## 🚀 Deployment

### Environment Variables

Create `.env` file:
```env
# Server
NODE_ENV=production
PORT=3000
API_VERSION=v1

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hr_platform
DB_USER=postgres
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRATION=24h

# CORS
ALLOWED_ORIGINS=https://yourapp.com,https://www.yourapp.com

# Email (for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# File Upload
MAX_FILE_SIZE=5242880  # 5MB
UPLOAD_DIR=./uploads

# Rate Limiting
RATE_LIMIT_WINDOW=15  # minutes
RATE_LIMIT_MAX_REQUESTS=100
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    env_file:
      - .env
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: hr_platform
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

---

## 🧪 Testing

### Test with cURL

```bash
# Login
curl -X POST https://api.hrplatform.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@hr.com",
    "password": "admin123",
    "role": "admin"
  }'

# Get employees (with token)
curl -X GET https://api.hrplatform.com/v1/employees \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 📞 Support

For implementation help:
- Email: support@hrplatform.com
- Documentation: See `api/index.html`
- OpenAPI Spec: See `api/openapi.yaml`
- Postman Collection: See `api/postman_collection.json`

