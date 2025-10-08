# 🚀 Quick Start - Backend API Integration

Get your HR Platform backend API running in 5 minutes!

## ⚡ Prerequisites

- Node.js 18+
- PostgreSQL 12+
- Git

## 🏃‍♂️ Quick Setup

### 1. Backend Setup (2 minutes)

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your PostgreSQL credentials
# Minimum required: DB_PASSWORD=your_postgres_password
```

### 2. Database Setup (1 minute)

```bash
# Create database
createdb -U postgres hr_platform

# Initialize database with sample data
npm run setup
```

### 3. Start Backend (30 seconds)

```bash
# Start development server
npm run dev
```

✅ **Backend running at:** `http://localhost:3000`

### 4. Test Backend (30 seconds)

```bash
# Health check
curl http://localhost:3000/health

# Test login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@hr.com","password":"admin123","role":"admin"}'
```

### 5. Run Flutter App (1 minute)

```bash
# In project root directory
flutter run
```

## 🎯 Test Login Credentials

**Organization Admin:**
- Email: `admin@hr.com`
- Password: `admin123`
- Role: Admin

**Employee:**
- Email: `employee@hr.com`
- Password: `employee123`
- Role: Employee

**Super Admin:**
- Email: `superadmin@hrplatform.com`
- Password: `super123`
- Role: Admin

## 🔧 Configuration

### For Android Emulator

Update `lib/services/api_client.dart`:
```dart
static const String _baseUrl = 'http://10.0.2.2:3000/api/v1';
```

### For Physical Device

Find your computer's IP address and update:
```dart
static const String _baseUrl = 'http://YOUR_IP:3000/api/v1';
```

## 🐛 Troubleshooting

**Database connection error?**
```bash
# Check PostgreSQL is running
pg_ctl status

# Restart PostgreSQL if needed
brew services restart postgresql  # macOS
sudo service postgresql restart   # Linux
```

**Port 3000 already in use?**
```bash
# Change port in .env file
PORT=3001
```

**Flutter connection error?**
- Check API base URL in `api_client.dart`
- Ensure backend is running on correct port
- For emulator, use `10.0.2.2` instead of `localhost`

## 📊 What's Included

✅ **Authentication System**
- JWT-based auth with refresh tokens
- Role-based access control
- Multi-tenant data isolation

✅ **Core Features**
- Organization management
- Employee CRUD operations
- User management
- API documentation

✅ **Security**
- Password hashing
- Rate limiting
- CORS protection
- Input validation

✅ **Database**
- PostgreSQL with proper relationships
- Sample data for testing
- Migration system

## 🚀 Next Steps

1. **Test the integration** - Login and verify data flows
2. **Customize** - Add your organization's data
3. **Deploy** - Use Railway, Render, or Heroku
4. **Extend** - Add more features like leave requests, attendance

## 📞 Need Help?

Check the detailed `BACKEND_INTEGRATION_GUIDE.md` for:
- Detailed setup instructions
- Troubleshooting guide
- Production deployment
- API documentation

---

**🎉 You're all set!** Your Flutter HR app now has a real backend API!
