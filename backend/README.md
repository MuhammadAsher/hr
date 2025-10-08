# HR Platform API

Multi-tenant HR Management System Backend API built with Node.js, Express, and PostgreSQL.

## Features

- 🔐 JWT-based authentication with role-based access control
- 🏢 Multi-tenant architecture with data isolation
- 👥 Organization, user, and employee management
- 📊 RESTful API with comprehensive validation
- 🛡️ Security middleware (helmet, rate limiting, CORS)
- 📝 Comprehensive API documentation

## Quick Start

### Prerequisites

- Node.js 18+ 
- PostgreSQL 12+
- npm or yarn

### Installation

1. **Clone and navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials and secrets
   ```

4. **Set up PostgreSQL database:**
   ```bash
   # Create database
   createdb hr_platform
   
   # Or using psql
   psql -U postgres -c "CREATE DATABASE hr_platform;"
   ```

5. **Initialize database:**
   ```bash
   npm run migrate
   ```

6. **Start development server:**
   ```bash
   npm run dev
   ```

The API will be available at `http://localhost:3000`

## Environment Variables

Copy `.env.example` to `.env` and configure:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hr_platform
DB_USER=postgres
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=24h

# Server
PORT=3000
NODE_ENV=development
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/logout` - User logout  
- `POST /api/v1/auth/refresh` - Refresh JWT token
- `GET /api/v1/auth/me` - Get current user profile

### Organizations (Super Admin only)
- `GET /api/v1/organizations` - List all organizations
- `POST /api/v1/organizations` - Create organization
- `GET /api/v1/organizations/:id` - Get organization details
- `PUT /api/v1/organizations/:id` - Update organization
- `GET /api/v1/organizations/:id/stats` - Get organization statistics

### Employees
- `GET /api/v1/employees` - List employees
- `POST /api/v1/employees` - Create employee (Admin only)
- `GET /api/v1/employees/:id` - Get employee details
- `PUT /api/v1/employees/:id` - Update employee (Admin only)
- `DELETE /api/v1/employees/:id` - Delete employee (Admin only)

## Default Users

After initialization, these users are available:

### Super Admin
- **Email:** `superadmin@hrplatform.com`
- **Password:** `super123`
- **Role:** Platform Administrator

### Organization Admin
- **Email:** `admin@hr.com`
- **Password:** `admin123`
- **Role:** Organization Admin

### Employee
- **Email:** `employee@hr.com`
- **Password:** `employee123`
- **Role:** Employee

## Testing the API

### Using curl

1. **Login:**
   ```bash
   curl -X POST http://localhost:3000/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "admin@hr.com",
       "password": "admin123",
       "role": "admin"
     }'
   ```

2. **Use the returned token:**
   ```bash
   curl -X GET http://localhost:3000/api/v1/employees \
     -H "Authorization: Bearer YOUR_JWT_TOKEN"
   ```

### Using the API Documentation

Visit the API documentation at `/api/` (when served) or check the `../api/` folder for:
- Interactive Swagger UI documentation
- Postman collection
- OpenAPI specification

## Database Schema

The API uses PostgreSQL with the following main tables:

- `organizations` - Organization/company data
- `users` - User accounts with authentication
- `employees` - Employee profiles and HR data

All tables include proper indexes and foreign key constraints for data integrity and performance.

## Security Features

- JWT authentication with configurable expiration
- Password hashing with bcrypt
- Rate limiting to prevent abuse
- CORS configuration for cross-origin requests
- Input validation and sanitization
- SQL injection prevention with Sequelize ORM
- Multi-tenant data isolation

## Development

### Available Scripts

- `npm start` - Start production server
- `npm run dev` - Start development server with auto-reload
- `npm test` - Run tests
- `npm run migrate` - Initialize/migrate database

### Project Structure

```
backend/
├── src/
│   ├── database/
│   │   ├── connection.js     # Database connection
│   │   └── init.js          # Database initialization
│   ├── middleware/
│   │   └── auth.js          # Authentication middleware
│   ├── models/
│   │   ├── Organization.js   # Organization model
│   │   ├── User.js          # User model
│   │   ├── Employee.js      # Employee model
│   │   └── index.js         # Model associations
│   ├── routes/
│   │   ├── auth.js          # Authentication routes
│   │   ├── organizations.js # Organization routes
│   │   └── employees.js     # Employee routes
│   └── server.js            # Express server setup
├── .env.example             # Environment variables template
├── package.json             # Dependencies and scripts
└── README.md               # This file
```

## Deployment

The API is ready for deployment to platforms like:

- Railway
- Render  
- Heroku
- DigitalOcean App Platform
- AWS/GCP/Azure

Make sure to:
1. Set production environment variables
2. Use a production PostgreSQL database
3. Set `NODE_ENV=production`
4. Configure proper CORS origins

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details
