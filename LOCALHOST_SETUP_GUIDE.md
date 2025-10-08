# 🚀 HR Platform - Complete Localhost Setup Guide

This guide will walk you through setting up the HR Platform backend API and Flutter app on your local machine step by step.

## 📋 Prerequisites

Before starting, make sure you have:

- **Node.js 18+** installed
- **Flutter SDK** installed and configured
- **Git** installed
- **Terminal/Command Prompt** access

## 🔧 Backend Setup (Node.js + SQLite)

### Step 1: Navigate to Backend Directory

```bash
cd backend
```

### Step 2: Install Dependencies

```bash
npm install
```

### Step 3: Setup Environment Variables

```bash
# Copy the example environment file
cp .env.example .env
```

The `.env` file contains:
```env
# Database Configuration (SQLite - no setup required!)
DB_PATH=./database.sqlite

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Server Configuration
PORT=3000
NODE_ENV=development

# CORS Configuration
CORS_ORIGIN=http://localhost:*
```

### Step 4: Initialize Database

```bash
npm run setup
```

This command will:
- Create SQLite database file
- Set up all tables (organizations, users, employees)
- Create sample users with default credentials

### Step 5: Start the Backend Server

```bash
npm run dev
```

You should see:
```
✅ Database connection established successfully.
✅ Database models validated.
🚀 HR Platform API server running on port 3000
📚 Environment: development
🔗 Health check: http://localhost:3000/health
```

### Step 6: Test the API

Open a new terminal and test the health endpoint:

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{"status":"OK","timestamp":"2025-10-08T23:26:46.521Z","uptime":19.506330708,"environment":"development"}
```

Test login with admin credentials:

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@hr.com", "password": "admin123", "role": "admin"}'
```

Expected response:
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "email": "admin@hr.com",
    "name": "Admin User",
    "role": "admin",
    "organizationId": "...",
    "organization": {
      "name": "Tech Solutions Inc."
    }
  }
}
```

## 📱 Flutter App Setup

### Step 1: Navigate to Flutter Project Root

```bash
cd ..  # Go back to project root
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

### Step 3: Configure API Base URL

The Flutter app is already configured to use `http://localhost:3000/api/v1` for the API base URL.

**Important for Android Emulator:**
If you're using Android emulator, you need to change the API base URL in `lib/services/api_client.dart`:

```dart
// For Android emulator, change localhost to 10.0.2.2
static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

// For iOS simulator or physical device on same network, keep:
static const String baseUrl = 'http://localhost:3000/api/v1';
```

### Step 4: Run the Flutter App

```bash
flutter run
```

Choose your target device (iOS simulator, Android emulator, or physical device).

## 🔑 Default Login Credentials

The system comes with three pre-configured users:

| Role | Email | Password | Description |
|------|-------|----------|-------------|
| **Super Admin** | `superadmin@hrplatform.com` | `super123` | Platform administrator |
| **Organization Admin** | `admin@hr.com` | `admin123` | Organization manager |
| **Employee** | `employee@hr.com` | `employee123` | Regular employee |

## 🧪 Testing the Integration

### 1. Test Backend API Endpoints

```bash
# Health check
curl http://localhost:3000/health

# Login as admin
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@hr.com", "password": "admin123", "role": "admin"}'

# Login as employee
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "employee@hr.com", "password": "employee123", "role": "employee"}'
```

### 2. Test Flutter App

1. **Launch the app** with `flutter run`
2. **Login** using any of the default credentials
3. **Navigate** through the app to test different features
4. **Check console logs** for any API communication issues

## 🔧 Troubleshooting

### Backend Issues

**Port 3000 already in use:**
```bash
# Kill any process using port 3000
lsof -ti:3000 | xargs kill -9
# Then restart the server
npm run dev
```

**Database issues:**
```bash
# Reset the database completely
rm -f database.sqlite
npm run setup
```

**SQLite foreign key constraint errors:**
This has been fixed in the current setup. If you encounter this, the setup script handles it automatically.

### Flutter Issues

**API connection failed:**
- Ensure backend server is running on port 3000
- For Android emulator, use `10.0.2.2:3000` instead of `localhost:3000`
- For physical device, use your computer's IP address instead of localhost

**Build errors:**
```bash
flutter clean
flutter pub get
flutter run
```

## 📁 Project Structure

```
hr/
├── backend/                 # Node.js API server
│   ├── src/
│   │   ├── models/         # Database models
│   │   ├── routes/         # API routes
│   │   ├── middleware/     # Authentication middleware
│   │   └── database/       # Database configuration
│   ├── database.sqlite     # SQLite database file
│   ├── package.json        # Node.js dependencies
│   └── .env               # Environment variables
├── lib/                    # Flutter app source
│   ├── models/            # Data models
│   ├── services/          # API services
│   ├── providers/         # State management
│   └── screens/           # UI screens
└── pubspec.yaml           # Flutter dependencies
```

## 🎯 Next Steps

1. **Customize the data** - Add your organization's information
2. **Test all features** - Login, employee management, etc.
3. **Extend functionality** - Add new features as needed
4. **Deploy to production** - When ready for live use

## 🆘 Getting Help

If you encounter any issues:

1. **Check the console logs** in both backend terminal and Flutter debug console
2. **Verify all prerequisites** are installed correctly
3. **Ensure ports are not blocked** by firewall
4. **Check network connectivity** between Flutter app and backend

Your HR Platform is now ready for local development and testing! 🎉
