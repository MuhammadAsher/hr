# Multi-Tenant Implementation Guide

## 🎯 Quick Start Guide

This guide will help you understand and implement the multi-tenant architecture in your HR Management System.

## 📋 What Has Been Created

### ✅ Completed Components

1. **Organization Model** (`lib/models/organization.dart`)
   - Complete organization data structure
   - Subscription plan definitions
   - Employee limits and pricing

2. **Organization Service** (`lib/services/organization_service.dart`)
   - CRUD operations for organizations
   - Subscription management
   - Platform statistics
   - Search and filtering

3. **Organization Registration Screen** (`lib/screens/organization_registration_screen.dart`)
   - 3-step registration wizard
   - Organization details form
   - Plan selection interface
   - Admin account creation

4. **Super Admin Dashboard** (`lib/screens/super_admin_dashboard.dart`)
   - Platform overview statistics
   - Organization management
   - Search and filter organizations
   - Activate/deactivate organizations

5. **Updated User Model** (`lib/models/user.dart`)
   - Added `organizationId` field
   - Added `isSuperAdmin` flag

6. **Documentation**
   - Multi-tenant architecture overview
   - Visual diagrams
   - Implementation roadmap

## 🔄 What Needs to Be Updated

### Step 1: Update All Models to Include Organization ID

You need to add `organizationId` field to all existing models:

#### Employee Model
```dart
class Employee {
  final String id;
  final String organizationId; // ADD THIS
  final String name;
  // ... rest of fields
}
```

#### Department Model
```dart
class Department {
  final String id;
  final String organizationId; // ADD THIS
  final String name;
  // ... rest of fields
}
```

#### LeaveRequest Model
```dart
class LeaveRequest {
  final String id;
  final String organizationId; // ADD THIS
  final String employeeId;
  // ... rest of fields
}
```

#### Attendance Model
```dart
class Attendance {
  final String id;
  final String organizationId; // ADD THIS
  final String employeeId;
  // ... rest of fields
}
```

#### Task Model
```dart
class Task {
  final String id;
  final String organizationId; // ADD THIS
  final String employeeId;
  // ... rest of fields
}
```

#### Payslip Model
```dart
class Payslip {
  final String id;
  final String organizationId; // ADD THIS
  final String employeeId;
  // ... rest of fields
}
```

### Step 2: Update All Services to Filter by Organization

Each service method should filter data by `organizationId`:

#### Example: EmployeeService
```dart
class EmployeeService {
  Future<List<Employee>> getAllEmployees(String organizationId) async {
    // Filter by organizationId
    return _employees
        .where((e) => e.organizationId == organizationId)
        .toList();
  }

  Future<Employee?> getEmployeeById(String id, String organizationId) async {
    try {
      return _employees.firstWhere(
        (e) => e.id == id && e.organizationId == organizationId,
      );
    } catch (e) {
      return null;
    }
  }
}
```

Apply similar changes to:
- `LeaveService`
- `AttendanceService`
- `TaskService`
- `PayslipService`
- `DepartmentService`

### Step 3: Update Authentication Service

Update `AuthService` to handle organization context:

```dart
class AuthService {
  Future<User?> login(String email, String password, UserRole role) async {
    // Existing login logic
    
    // Add organizationId to user
    final user = User(
      id: userData['id'],
      email: email,
      name: userData['name'],
      role: role,
      organizationId: userData['organizationId'], // ADD THIS
      isSuperAdmin: userData['isSuperAdmin'] ?? false,
    );
    
    return user;
  }
}
```

### Step 4: Create Organization Context Provider

Create a provider to manage current organization context:

```dart
// lib/providers/organization_provider.dart
import 'package:flutter/foundation.dart';
import '../models/organization.dart';

class OrganizationProvider extends ChangeNotifier {
  Organization? _currentOrganization;
  
  Organization? get currentOrganization => _currentOrganization;
  
  void setOrganization(Organization org) {
    _currentOrganization = org;
    notifyListeners();
  }
  
  void clearOrganization() {
    _currentOrganization = null;
    notifyListeners();
  }
  
  String get organizationId => _currentOrganization?.id ?? '';
}
```

### Step 5: Update Main App to Include Provider

```dart
// lib/main.dart
import 'package:provider/provider.dart';
import 'providers/organization_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrganizationProvider()), // ADD THIS
      ],
      child: const MyApp(),
    ),
  );
}
```

### Step 6: Update Login Flow

```dart
// After successful login
final user = await authService.login(email, password, role);

if (user != null) {
  // Load organization
  final org = await organizationService.getOrganizationById(user.organizationId);
  
  // Set organization context
  Provider.of<OrganizationProvider>(context, listen: false)
      .setOrganization(org!);
  
  // Navigate to appropriate dashboard
  if (user.isSuperAdmin) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SuperAdminDashboard()),
    );
  } else if (user.role == UserRole.admin) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AdminDashboard()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => EmployeeDashboard()),
    );
  }
}
```

### Step 7: Update All Screens to Use Organization Context

```dart
// Example: In any screen that needs organization data
class EmployeeListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final organizationId = Provider.of<OrganizationProvider>(context)
        .organizationId;
    
    return FutureBuilder<List<Employee>>(
      future: employeeService.getAllEmployees(organizationId), // Pass org ID
      builder: (context, snapshot) {
        // Build UI
      },
    );
  }
}
```

## 🚀 Testing the Multi-Tenant System

### Test Scenario 1: Register New Organization

1. Run the app
2. Navigate to Organization Registration
3. Fill in organization details:
   - Name: "Test Company Inc."
   - Email: "admin@testcompany.com"
   - Phone: "+1-555-1234"
   - Address: "123 Test Street"
   - Industry: "Technology"
4. Select a subscription plan
5. Create admin account
6. Verify organization is created

### Test Scenario 2: Super Admin Access

1. Login as super admin
2. View platform dashboard
3. See all organizations
4. View platform statistics
5. Manage organizations (activate/deactivate)

### Test Scenario 3: Organization Admin Access

1. Login as organization admin
2. Verify only their organization's data is visible
3. Add employees
4. Manage departments
5. Process leave requests

### Test Scenario 4: Data Isolation

1. Create two organizations
2. Add employees to each
3. Login as admin of Organization 1
4. Verify you can only see Organization 1's employees
5. Login as admin of Organization 2
6. Verify you can only see Organization 2's employees

## 📊 Database Schema (For Production)

When moving to production with a real database:

```sql
-- Organizations table
CREATE TABLE organizations (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    industry VARCHAR(100),
    logo VARCHAR(500),
    registered_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subscription_plan VARCHAR(50) DEFAULT 'Free',
    is_active BOOLEAN DEFAULT true,
    employee_limit INT DEFAULT 10,
    settings JSONB,
    admin_id VARCHAR(50),
    tax_id VARCHAR(100),
    website VARCHAR(255)
);

-- Users table
CREATE TABLE users (
    id VARCHAR(50) PRIMARY KEY,
    organization_id VARCHAR(50) REFERENCES organizations(id),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    is_super_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Employees table
CREATE TABLE employees (
    id VARCHAR(50) PRIMARY KEY,
    organization_id VARCHAR(50) REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    department VARCHAR(100),
    position VARCHAR(100),
    phone VARCHAR(50),
    join_date DATE,
    salary DECIMAL(10, 2),
    UNIQUE(organization_id, email)
);

-- Add organization_id to all other tables
-- leave_requests, attendance, tasks, payslips, departments, etc.
```

## 🔐 Security Best Practices

1. **Row-Level Security**
   - Implement database-level security
   - Ensure queries always filter by organization_id

2. **API Security**
   - Include organization context in JWT tokens
   - Validate organization access on every request

3. **Data Encryption**
   - Encrypt sensitive data at rest
   - Use HTTPS for all communications

4. **Audit Logging**
   - Log all organization changes
   - Track cross-organization access attempts

## 📈 Monitoring & Analytics

Track these metrics for each organization:

1. **Usage Metrics**
   - Number of employees
   - Active users
   - Feature usage
   - Storage used

2. **Business Metrics**
   - Subscription plan
   - Monthly recurring revenue
   - Churn rate
   - Customer lifetime value

3. **Performance Metrics**
   - Response times
   - Error rates
   - Uptime
   - API usage

## 🎓 Next Steps

1. ✅ Review the architecture documentation
2. ⏳ Update all models with organizationId
3. ⏳ Update all services to filter by organization
4. ⏳ Implement organization context provider
5. ⏳ Update authentication flow
6. ⏳ Test multi-tenant functionality
7. ⏳ Implement backend API
8. ⏳ Set up database with proper schemas
9. ⏳ Implement payment integration
10. ⏳ Deploy to production

## 📞 Support

For questions or issues during implementation:
- Review the MULTI_TENANT_ARCHITECTURE.md file
- Check the code examples in this guide
- Test with the provided mock data first
- Implement backend integration last

---

**Remember:** The foundation is now in place. The key is to systematically update each component to be organization-aware while maintaining data isolation and security.

