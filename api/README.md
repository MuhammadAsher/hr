# 📚 HR Management SaaS Platform - API Documentation

Complete API documentation for the multi-tenant HR Management System.

---

## 🌐 View Documentation Online

### Option 1: GitHub Pages (Recommended - FREE)

1. **Push to GitHub:**
   ```bash
   git add api/
   git commit -m "Add API documentation"
   git push origin main
   ```

2. **Enable GitHub Pages:**
   - Go to your repository on GitHub
   - Click **Settings** → **Pages**
   - Source: Deploy from a branch
   - Branch: `main` → `/api` folder
   - Click **Save**

3. **Access your documentation:**
   ```
   https://YOUR_USERNAME.github.io/YOUR_REPO_NAME/
   ```

### Option 2: Netlify (FREE)

1. **Create `netlify.toml` in api folder:**
   ```toml
   [build]
     publish = "api"
   
   [[redirects]]
     from = "/*"
     to = "/index.html"
     status = 200
   ```

2. **Deploy:**
   - Go to https://netlify.com
   - Drag and drop the `api` folder
   - Your docs will be live at: `https://YOUR_SITE.netlify.app`

### Option 3: Vercel (FREE)

1. **Install Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **Deploy:**
   ```bash
   cd api
   vercel
   ```

3. **Your docs will be live at:**
   ```
   https://YOUR_PROJECT.vercel.app
   ```

### Option 4: Swagger Hub (FREE for public APIs)

1. Go to https://app.swaggerhub.com/
2. Create account
3. Click **Create New** → **Import and Document API**
4. Upload `openapi.yaml`
5. Your docs will be at: `https://app.swaggerhub.com/apis/YOUR_USERNAME/hr-platform/1.0.0`

### Option 5: Local Server

```bash
# Using Python
cd api
python -m http.server 8000

# Using Node.js
npx http-server api -p 8000

# Then open: http://localhost:8000
```

---

## 📁 Files Included

```
api/
├── index.html                  # Swagger UI documentation page
├── openapi.yaml               # OpenAPI 3.0 specification
├── postman_collection.json    # Postman collection for testing
├── IMPLEMENTATION_GUIDE.md    # Backend implementation guide
└── README.md                  # This file
```

---

## 🚀 Quick Start

### 1. View Documentation Locally

Simply open `api/index.html` in your web browser. The Swagger UI will load with:
- ✅ Interactive API documentation
- ✅ Try-it-out functionality
- ✅ Request/response examples
- ✅ Schema definitions

### 2. Import to Postman

1. Open Postman
2. Click **Import**
3. Select `api/postman_collection.json`
4. Set variables:
   - `base_url`: Your API endpoint
   - `jwt_token`: Will be auto-filled after login

### 3. Test API Endpoints

```bash
# Login to get token
curl -X POST https://api.hrplatform.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@hr.com",
    "password": "admin123",
    "role": "admin"
  }'

# Use token for authenticated requests
curl -X GET https://api.hrplatform.com/v1/employees \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 📖 API Overview

### Base URL
```
Production: https://api.hrplatform.com/v1
Staging:    https://staging-api.hrplatform.com/v1
Local:      http://localhost:3000/v1
```

### Authentication
All endpoints (except login/register) require JWT authentication:
```
Authorization: Bearer <your_jwt_token>
```

### Multi-Tenancy
All data is automatically scoped to the authenticated user's organization.

---

## 🔑 API Endpoints

### Authentication
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout
- `POST /auth/refresh` - Refresh JWT token

### Organizations (Super Admin Only)
- `GET /organizations` - List all organizations
- `POST /organizations` - Create organization
- `GET /organizations/{id}` - Get organization details
- `PUT /organizations/{id}` - Update organization
- `DELETE /organizations/{id}` - Delete organization
- `GET /organizations/{id}/stats` - Get organization statistics

### Employees
- `GET /employees` - List employees
- `POST /employees` - Create employee
- `GET /employees/{id}` - Get employee details
- `PUT /employees/{id}` - Update employee
- `DELETE /employees/{id}` - Delete employee

### Departments
- `GET /departments` - List departments
- `POST /departments` - Create department
- `GET /departments/{id}` - Get department details
- `PUT /departments/{id}` - Update department
- `DELETE /departments/{id}` - Delete department

### Leave Requests
- `GET /leave-requests` - List leave requests
- `POST /leave-requests` - Create leave request
- `GET /leave-requests/{id}` - Get leave request details
- `POST /leave-requests/{id}/approve` - Approve leave
- `POST /leave-requests/{id}/reject` - Reject leave

### Attendance
- `GET /attendance` - List attendance records
- `POST /attendance` - Record attendance
- `GET /attendance/{id}` - Get attendance details
- `PUT /attendance/{id}` - Update attendance

### Tasks
- `GET /tasks` - List tasks
- `POST /tasks` - Create task
- `GET /tasks/{id}` - Get task details
- `PUT /tasks/{id}` - Update task
- `DELETE /tasks/{id}` - Delete task

### Payslips
- `GET /payslips` - List payslips
- `POST /payslips` - Generate payslip
- `GET /payslips/{id}` - Get payslip details
- `GET /payslips/{id}/pdf` - Download payslip PDF

### Reports & Analytics
- `GET /reports/employees` - Employee reports
- `GET /reports/leave` - Leave reports
- `GET /reports/attendance` - Attendance reports
- `GET /reports/payroll` - Payroll reports

---

## 🎯 Example Requests

### Login
```bash
POST /v1/auth/login
Content-Type: application/json

{
  "email": "admin@hr.com",
  "password": "admin123",
  "role": "admin"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user_123",
    "email": "admin@hr.com",
    "name": "Admin User",
    "role": "admin",
    "organizationId": "org_001",
    "isSuperAdmin": false
  },
  "expiresIn": 86400
}
```

### Create Employee
```bash
POST /v1/employees
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john.doe@company.com",
  "phone": "+1-555-1234",
  "department": "Engineering",
  "position": "Software Engineer",
  "joinDate": "2024-01-15",
  "salary": 75000,
  "status": "active"
}
```

### Get Leave Requests
```bash
GET /v1/leave-requests?status=pending
Authorization: Bearer YOUR_TOKEN

Response:
[
  {
    "id": "leave_001",
    "employeeId": "emp_001",
    "employeeName": "John Doe",
    "leaveType": "vacation",
    "startDate": "2024-02-01",
    "endDate": "2024-02-05",
    "days": 5,
    "reason": "Family vacation",
    "status": "pending",
    "requestDate": "2024-01-20T10:30:00Z"
  }
]
```

---

## 🔒 Security

### JWT Token
- Tokens expire after 24 hours
- Include in Authorization header: `Bearer <token>`
- Refresh using `/auth/refresh` endpoint

### Rate Limiting
- 100 requests per 15 minutes per IP
- Authenticated users: 1000 requests per hour

### CORS
- Configured for specific origins
- Credentials allowed for authenticated requests

### Data Isolation
- All queries automatically filtered by organization
- Row-level security enforced at database level
- Super admins can access cross-organization data

---

## 📊 Response Formats

### Success Response
```json
{
  "data": { ... },
  "message": "Success"
}
```

### Error Response
```json
{
  "error": "Error type",
  "message": "Human-readable error message",
  "code": 400,
  "details": { ... }
}
```

### Paginated Response
```json
{
  "data": [ ... ],
  "total": 100,
  "page": 1,
  "limit": 20,
  "totalPages": 5
}
```

---

## 🛠️ Implementation

See `IMPLEMENTATION_GUIDE.md` for:
- Database schema
- Authentication implementation
- API endpoint examples
- Deployment instructions
- Testing guidelines

---

## 📞 Support

- **Email:** support@hrplatform.com
- **Documentation:** https://YOUR_DOCS_URL
- **API Status:** https://status.hrplatform.com
- **GitHub Issues:** https://github.com/YOUR_REPO/issues

---

## 📝 License

MIT License - See LICENSE file for details

---

## 🎉 Quick Deploy Commands

### Deploy to GitHub Pages
```bash
git add api/
git commit -m "Add API documentation"
git push origin main
# Then enable GitHub Pages in repository settings
```

### Deploy to Netlify
```bash
cd api
netlify deploy --prod
```

### Deploy to Vercel
```bash
cd api
vercel --prod
```

---

**Your API documentation is ready to be deployed!** 🚀

Choose any of the hosting options above to make your API documentation publicly accessible.

