# 🚀 Backend API Integration Guide

Complete step-by-step guide to set up and integrate the backend API with your Flutter HR application.

## 📋 Prerequisites

Before starting, make sure you have:

- **Node.js 18+** installed
- **PostgreSQL 12+** installed and running
- **Flutter SDK** installed
- **Git** for version control

## 🛠️ Step 1: Backend Setup

### 1.1 Install Dependencies

```bash
cd backend
npm install
```

### 1.2 Set Up Environment Variables

```bash
cp .env.example .env
```

Edit `.env` file with your configuration:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hr_platform
DB_USER=postgres
DB_PASSWORD=your_postgres_password

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=24h

# Server Configuration
PORT=3000
NODE_ENV=development

# Super Admin Configuration
SUPER_ADMIN_EMAIL=superadmin@hrplatform.com
SUPER_ADMIN_PASSWORD=super123
SUPER_ADMIN_NAME=Platform Administrator
```

### 1.3 Set Up PostgreSQL Database

**Option A: Using psql command line**
```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE hr_platform;

# Exit psql
\q
```

**Option B: Using createdb command**
```bash
createdb -U postgres hr_platform
```

### 1.4 Initialize Database

```bash
npm run setup
```

This will:
- Create all database tables
- Set up relationships and indexes
- Create a super admin user
- Create sample organization with test users

### 1.5 Start Backend Server

```bash
npm run dev
```

The API will be available at `http://localhost:3000`

## 🧪 Step 2: Test Backend API

### 2.1 Health Check

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "OK",
  "timestamp": "2024-01-20T10:30:00.000Z",
  "uptime": 123.456,
  "environment": "development"
}
```

### 2.2 Test Authentication

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@hr.com",
    "password": "admin123",
    "role": "admin"
  }'
```

Expected response:
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-here",
    "email": "admin@hr.com",
    "name": "Admin User",
    "role": "admin",
    "organizationId": "org-uuid",
    "isSuperAdmin": false
  },
  "expiresIn": 86400
}
```

### 2.3 Test Protected Endpoint

```bash
# Use the token from login response
curl -X GET http://localhost:3000/api/v1/employees \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

## 📱 Step 3: Flutter Integration

### 3.1 Update API Base URL

If your backend is running on a different host/port, update the base URL in `lib/services/api_client.dart`:

```dart
static const String _baseUrl = 'http://localhost:3000/api/v1';
```

**For Android Emulator:**
```dart
static const String _baseUrl = 'http://10.0.2.2:3000/api/v1';
```

**For iOS Simulator:**
```dart
static const String _baseUrl = 'http://localhost:3000/api/v1';
```

**For Physical Device:**
```dart
static const String _baseUrl = 'http://YOUR_COMPUTER_IP:3000/api/v1';
```

### 3.2 Initialize API Client

Update `lib/main.dart` to initialize the API client:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API client
  await ApiClient().initialize();
  
  runApp(const MyApp());
}
```

### 3.3 Update AuthProvider

Update `lib/providers/auth_provider.dart` to initialize AuthService:

```dart
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthProvider() {
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    await _authService.initialize();
    await _loadUser();
  }
  
  // ... rest of the code
}
```

## 🔧 Step 4: Test Flutter Integration

### 4.1 Run Flutter App

```bash
flutter run
```

### 4.2 Test Login

Try logging in with these credentials:

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

### 4.3 Verify API Integration

1. **Login Flow**: Should authenticate against the backend API
2. **Employee List**: Should fetch employees from the backend
3. **Data Persistence**: Should maintain login state across app restarts

## 🐛 Troubleshooting

### Common Issues

**1. Connection Refused Error**
```
Error: Connection refused (OS Error: Connection refused, errno = 61)
```
- Make sure backend server is running on `http://localhost:3000`
- Check if the base URL in `api_client.dart` is correct

**2. Database Connection Error**
```
Unable to connect to the database
```
- Verify PostgreSQL is running
- Check database credentials in `.env` file
- Ensure database `hr_platform` exists

**3. JWT Token Errors**
```
Invalid token / Token expired
```
- Check if JWT_SECRET is set in `.env`
- Try logging out and logging in again

**4. CORS Errors (Web)**
```
Access to XMLHttpRequest blocked by CORS policy
```
- Update CORS configuration in `backend/src/server.js`
- Add your Flutter web URL to allowed origins

### Debug Mode

Enable debug logging in Flutter:

```dart
// In api_client.dart, add debug prints
print('API Request: $method $endpoint');
print('Response: ${response.statusCode} ${response.body}');
```

## 🚀 Step 5: Production Deployment

### 5.1 Deploy Backend

**Railway (Recommended):**
1. Connect your GitHub repository to Railway
2. Set environment variables in Railway dashboard
3. Deploy automatically on git push

**Render:**
1. Connect repository to Render
2. Set build command: `npm install`
3. Set start command: `npm start`
4. Configure environment variables

### 5.2 Update Flutter for Production

```dart
// In api_client.dart
static const String _baseUrl = 'https://your-api-domain.com/api/v1';
```

### 5.3 Build Flutter App

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release

# For Web
flutter build web --release
```

## 📊 API Endpoints Summary

| Endpoint | Method | Description | Auth Required |
|----------|--------|-------------|---------------|
| `/health` | GET | Health check | No |
| `/auth/login` | POST | User login | No |
| `/auth/logout` | POST | User logout | Yes |
| `/auth/me` | GET | Current user | Yes |
| `/organizations` | GET | List organizations | Super Admin |
| `/organizations` | POST | Create organization | Super Admin |
| `/employees` | GET | List employees | Yes |
| `/employees` | POST | Create employee | Admin |
| `/employees/:id` | GET | Get employee | Yes |
| `/employees/:id` | PUT | Update employee | Admin |
| `/employees/:id` | DELETE | Delete employee | Admin |

## 🎯 Next Steps

1. **Add More Models**: Implement LeaveRequest, Attendance, Task models
2. **Add Validation**: Implement comprehensive form validation
3. **Add Error Handling**: Improve error messages and user feedback
4. **Add Offline Support**: Implement local caching for offline usage
5. **Add Push Notifications**: Implement real-time notifications
6. **Add File Upload**: Support profile pictures and document uploads

## 📞 Support

If you encounter any issues:

1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Ensure environment variables are correctly set
4. Check backend logs for detailed error messages

---

**🎉 Congratulations!** Your Flutter HR app is now integrated with a real backend API!
