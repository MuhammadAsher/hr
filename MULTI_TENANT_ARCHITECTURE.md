# Multi-Tenant SaaS HR Management System

## 🏢 Overview

This HR Management System has been architected as a **Multi-Tenant SaaS Platform** where multiple organizations can register and use the system independently with complete data isolation.

## 📊 Hierarchical Structure

```
Platform (Your SaaS Company)
│
├── Super Admin (Platform Administrator)
│   ├── Manage all organizations
│   ├── View platform statistics
│   ├── Activate/Deactivate organizations
│   └── Manage subscription plans
│
└── Organizations (Multiple Companies)
    │
    ├── Organization 1 (Company A)
    │   ├── Organization Admin (HR Manager)
    │   ├── Departments
    │   │   ├── Engineering
    │   │   ├── Marketing
    │   │   └── Sales
    │   ├── Employees
    │   ├── Leave Requests
    │   ├── Attendance Records
    │   ├── Payslips
    │   └── Tasks
    │
    ├── Organization 2 (Company B)
    │   ├── Organization Admin (HR Manager)
    │   ├── Departments
    │   ├── Employees
    │   └── ... (isolated data)
    │
    └── Organization N...
```

## 🔑 Key Concepts

### 1. **Multi-Tenancy**
- Each organization is a separate tenant
- Complete data isolation between organizations
- Shared application infrastructure
- Organization-specific settings and configurations

### 2. **User Roles Hierarchy**

#### **Super Admin** (Platform Level)
- Your company's administrators
- Manage all organizations on the platform
- View platform-wide analytics
- Control subscription plans
- Activate/deactivate organizations

#### **Organization Admin** (Organization Level)
- HR Manager of each company
- Manage their organization's employees
- Handle leave requests, attendance, payroll
- Create departments and assign managers
- View organization-specific reports

#### **Employee** (Organization Level)
- Regular employees of each organization
- Apply for leaves
- View their attendance and payslips
- Access team directory
- Manage assigned tasks

### 3. **Subscription Plans**

#### **Free Plan**
- Up to 10 employees
- Basic employee management
- Leave management
- Attendance tracking
- **Price:** $0/month

#### **Basic Plan**
- Up to 50 employees
- All Free features
- Department management
- Reports & Analytics
- Email notifications
- **Price:** $49.99/month

#### **Premium Plan**
- Up to 200 employees
- All Basic features
- Advanced reporting
- PDF generation
- Team directory
- Priority support
- **Price:** $149.99/month

#### **Enterprise Plan**
- Unlimited employees
- All Premium features
- Custom integrations
- Dedicated support
- Custom branding
- API access
- **Price:** $499.99/month

## 🗄️ Data Model

### Organization Model
```dart
class Organization {
  String id;                    // Unique organization ID
  String name;                  // Company name
  String email;                 // Organization email
  String phone;                 // Contact number
  String address;               // Physical address
  String industry;              // Industry type
  String logo;                  // Company logo URL
  DateTime registeredDate;      // Registration date
  String subscriptionPlan;      // Current plan
  bool isActive;                // Active status
  int employeeLimit;            // Max employees allowed
  Map<String, dynamic> settings; // Organization settings
  String adminId;               // Primary admin user ID
  String taxId;                 // Tax identification
  String website;               // Company website
}
```

### Updated User Model
```dart
class User {
  String id;
  String email;
  String name;
  UserRole role;                // admin, employee
  String organizationId;        // Links user to organization
  bool isSuperAdmin;            // Platform super admin flag
}
```

### Data Isolation
All existing models (Employee, LeaveRequest, Attendance, etc.) will be filtered by `organizationId` to ensure data isolation.

## 🚀 Implementation Flow

### 1. **Organization Registration**
```
New Company → Register Organization → Choose Plan → Create Admin Account → Login
```

**Steps:**
1. Company fills organization details (name, email, address, industry)
2. Selects subscription plan (Free, Basic, Premium, Enterprise)
3. Creates admin account (email, password)
4. System creates organization record
5. Admin can login and start managing HR

### 2. **User Authentication Flow**
```
Login → Verify Credentials → Load Organization Context → Route to Dashboard
```

**Process:**
1. User enters email and password
2. System verifies credentials
3. Loads user's organization data
4. Sets organization context for session
5. Routes to appropriate dashboard:
   - Super Admin → Platform Dashboard
   - Organization Admin → Admin Dashboard
   - Employee → Employee Dashboard

### 3. **Data Access Pattern**
```
User Request → Check Organization ID → Filter Data → Return Results
```

**Example:**
```dart
// Get employees for current organization
Future<List<Employee>> getEmployees(String organizationId) async {
  return employees.where((e) => e.organizationId == organizationId).toList();
}
```

## 📁 New Files Created

### Models
- `lib/models/organization.dart` - Organization model and subscription plans

### Services
- `lib/services/organization_service.dart` - Organization CRUD operations

### Screens
- `lib/screens/organization_registration_screen.dart` - New organization signup
- `lib/screens/super_admin_dashboard.dart` - Platform administration

## 🔄 Required Updates to Existing Code

### 1. **Update All Models**
Add `organizationId` field to:
- ✅ User (already updated)
- ⏳ Employee
- ⏳ Department
- ⏳ LeaveRequest
- ⏳ Attendance
- ⏳ Task
- ⏳ Payslip

### 2. **Update All Services**
Filter all queries by `organizationId`:
- ⏳ EmployeeService
- ⏳ LeaveService
- ⏳ AttendanceService
- ⏳ TaskService
- ⏳ PayslipService
- ⏳ DepartmentService

### 3. **Update Authentication**
- ⏳ Add organization context to login
- ⏳ Store current organization in session
- ⏳ Add super admin login flow

### 4. **Update UI**
- ⏳ Add organization selector for super admin
- ⏳ Show organization name in app bar
- ⏳ Add organization settings screen

## 🎯 Benefits of This Architecture

### For Your Company (Platform Owner)
1. **Scalable Revenue Model** - Subscription-based pricing
2. **Multiple Clients** - Serve unlimited organizations
3. **Centralized Management** - Manage all clients from one dashboard
4. **Analytics** - Platform-wide insights and metrics
5. **Easy Onboarding** - Self-service registration

### For Client Organizations
1. **Quick Setup** - Register and start in minutes
2. **No Infrastructure** - Cloud-based solution
3. **Flexible Plans** - Choose plan based on size
4. **Data Security** - Complete data isolation
5. **Regular Updates** - Automatic feature updates

### For End Users (Employees)
1. **Easy Access** - Simple login with organization context
2. **Familiar Interface** - Consistent user experience
3. **Mobile Ready** - Access from anywhere
4. **Secure** - Organization-level data protection

## 🔐 Security Considerations

### Data Isolation
- All queries filtered by `organizationId`
- No cross-organization data access
- Separate database schemas (in production)

### Access Control
- Role-based permissions (Super Admin, Admin, Employee)
- Organization-level access restrictions
- API authentication with organization context

### Compliance
- GDPR compliance for data privacy
- Data export capabilities
- Right to be forgotten implementation

## 🚀 Next Steps for Production

### Backend Implementation
1. **Database Setup**
   - PostgreSQL with row-level security
   - Separate schemas per organization
   - Encrypted data storage

2. **API Development**
   - RESTful API with organization context
   - JWT authentication with org claims
   - Rate limiting per organization

3. **File Storage**
   - Organization-specific S3 buckets
   - Secure document storage
   - CDN for static assets

### Payment Integration
1. **Stripe Integration**
   - Subscription management
   - Automatic billing
   - Invoice generation
   - Payment history

2. **Plan Management**
   - Upgrade/downgrade flows
   - Proration handling
   - Trial periods

### Monitoring & Analytics
1. **Platform Metrics**
   - Organization growth
   - Revenue tracking
   - Usage statistics
   - Performance monitoring

2. **Organization Metrics**
   - Employee count trends
   - Feature usage
   - Support tickets
   - Satisfaction scores

## 📞 Support

For implementation questions or assistance, refer to:
- Technical Documentation
- API Reference
- Integration Guides
- Support Portal

---

**Version:** 1.0  
**Last Updated:** 2024  
**Status:** Architecture Defined - Implementation in Progress

