# 🗄️ Database Management Commands

## Quick Database Viewing

### 1. **View All Data (Formatted)**
```bash
cd backend
node view-database.js
```

### 2. **SQLite Command Line**
```bash
cd backend
sqlite3 database.sqlite

# Inside SQLite:
.tables                          # Show all tables
.schema                          # Show table structures
.schema users                    # Show specific table structure
SELECT * FROM users;             # View all users
SELECT * FROM organizations;     # View all organizations
SELECT * FROM employees;         # View all employees
.exit                           # Exit SQLite
```

### 3. **Quick SQL Queries**
```bash
# View users with organization names
cd backend
sqlite3 database.sqlite "
SELECT u.name, u.email, u.role, o.name as organization 
FROM users u 
LEFT JOIN organizations o ON u.organization_id = o.id;
"

# View user count by role
sqlite3 database.sqlite "
SELECT role, COUNT(*) as count 
FROM users 
GROUP BY role;
"

# View organization details
sqlite3 database.sqlite "
SELECT name, email, industry, subscription_plan, employee_limit 
FROM organizations;
"
```

## Database Management

### 4. **Reset Database**
```bash
cd backend
rm -f database.sqlite
npm run setup
```

### 5. **Backup Database**
```bash
cd backend
cp database.sqlite database_backup_$(date +%Y%m%d_%H%M%S).sqlite
```

### 6. **Restore Database**
```bash
cd backend
cp database_backup_YYYYMMDD_HHMMSS.sqlite database.sqlite
```

## API Testing Commands

### 7. **Test API Endpoints**
```bash
# Health check
curl http://localhost:3000/health

# Login as admin
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@hr.com", "password": "admin123", "role": "admin"}'

# Get employees (need token from login)
curl -X GET http://localhost:3000/api/v1/employees \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Create employee
curl -X POST http://localhost:3000/api/v1/employees \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "name": "Jane Doe",
    "email": "jane@hr.com",
    "department": "Engineering",
    "position": "Software Developer",
    "salary": 75000,
    "join_date": "2025-01-01"
  }'
```

## Server Management

### 8. **Server Commands**
```bash
# Start server
cd backend
npm run dev

# Stop server (if running in background)
lsof -ti:3000 | xargs kill -9

# View server logs (if running)
# Check the terminal where npm run dev is running
```

## Database Schema Information

### 9. **Table Structures**

**Users Table:**
- id (UUID, Primary Key)
- organization_id (UUID, Foreign Key)
- email (String, Unique per organization)
- password_hash (String)
- name (String)
- role (admin/employee)
- is_super_admin (Boolean)
- is_active (Boolean)
- last_login (DateTime)
- email_verified (Boolean)

**Organizations Table:**
- id (UUID, Primary Key)
- name (String)
- email (String, Unique)
- industry (String)
- subscription_plan (String)
- is_active (Boolean)
- employee_limit (Integer)
- admin_id (UUID)

**Employees Table:**
- id (UUID, Primary Key)
- organization_id (UUID, Foreign Key)
- user_id (UUID, Foreign Key)
- employee_id (String, Unique per organization)
- name (String)
- email (String, Unique per organization)
- department (String)
- position (String)
- salary (Decimal)
- status (active/inactive)
- join_date (Date)

## Default Login Credentials

| Role | Email | Password |
|------|-------|----------|
| Super Admin | superadmin@hrplatform.com | super123 |
| Org Admin | admin@hr.com | admin123 |
| Employee | employee@hr.com | employee123 |

## File Locations

- **Database File**: `backend/database.sqlite`
- **Environment Config**: `backend/.env`
- **Server Code**: `backend/src/server.js`
- **Models**: `backend/src/models/`
- **Routes**: `backend/src/routes/`
- **Database Viewer**: `backend/view-database.js`
