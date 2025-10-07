# HR Management App - Features Documentation

## Overview
This is a Flutter-based HR Management application with role-based authentication supporting Admin and Employee users.

## Features Implemented

### 1. Authentication System ✅
- **Login Screen** with role-based segmented control
- Switch between Admin and Employee login modes
- Email and password validation
- Persistent authentication using SharedPreferences
- Auto-login on app restart if session exists

### 2. Role-Based Dashboards ✅

#### Admin Dashboard
- Welcome card with user profile
- Statistics overview:
  - Total Employees
  - Departments
  - Pending Leaves
  - Active Projects
- Quick Actions:
  - ✅ **Manage Employees** - Full CRUD operations
  - ✅ **Approve Leave Requests** - Review and approve/reject leaves
  - 🔜 View Reports (Coming Soon)
  - 🔜 Manage Departments (Coming Soon)
- Logout functionality

#### Employee Dashboard
- Welcome card with user profile
- Personal statistics:
  - Leave Balance
  - Attendance Percentage
  - Tasks Count
  - Projects Count
- Quick Actions:
  - ✅ **Apply for Leave** - Submit leave requests
  - ✅ **View Payslips** - View detailed salary breakdowns
  - ✅ **My Attendance** - Track attendance history
  - ✅ **My Tasks** - Manage assigned tasks
  - 🔜 Team Directory (Coming Soon)
- Logout functionality

### 3. Employee Management (Admin) ✅
- **View All Employees** - List with search functionality
- **Add New Employee** - Complete employee registration form
- **Edit Employee** - Update employee information
- **Delete Employee** - Remove employees with confirmation
- **Search Employees** - Real-time search by name, email, department, or position
- **Employee Details** - View complete employee information
- Fields: Name, Email, Phone, Department, Position, Salary, Join Date, Status

### 4. Leave Management ✅

#### For Employees:
- **Apply for Leave** - Submit new leave requests
- **Leave Types**: Annual, Sick, Casual, Maternity, Paternity, Unpaid
- **Date Selection** - Pick start and end dates
- **Auto-calculate** - Automatic calculation of leave days
- **View My Requests** - See all submitted leave requests with status
- **Status Tracking** - Pending, Approved, or Rejected

#### For Admin:
- **View All Requests** - See all employee leave requests
- **Filter by Status** - All, Pending, Approved, Rejected
- **Approve/Reject** - Quick action buttons for pending requests
- **Request Details** - View complete leave request information
- **Approval Tracking** - Track who approved and when

### 5. Task Management (Employee) ✅
- **View All Tasks** - See all assigned tasks
- **Task Statistics** - Todo, In Progress, Completed counts
- **Filter Tasks** - Filter by status
- **Task Details** - Title, description, due date, priority, assigned by
- **Update Status** - Change task status (Todo → In Progress → Completed)
- **Priority Levels** - High, Medium, Low with color coding
- **Overdue Alerts** - Visual indicators for overdue tasks

### 6. Attendance Tracking (Employee) ✅
- **Attendance History** - View past 30 days of attendance
- **Attendance Statistics**:
  - Overall attendance percentage
  - Present days count
  - Leave days count
  - Half days count
- **Daily Records** - Check-in/check-out times
- **Working Hours** - Automatic calculation of daily working hours
- **Status Types** - Present, Absent, Leave, Half Day
- **Visual Dashboard** - Beautiful gradient card with stats

### 7. Payslip Management (Employee) ✅
- **View Payslips** - List of all monthly payslips
- **Detailed Breakdown**:
  - Basic Salary
  - Allowances (Housing, Transport, Medical)
  - Deductions (Tax, Insurance, Provident Fund)
  - Gross Salary calculation
  - Net Salary display
- **Monthly History** - Access payslips from previous months
- **Download Option** - PDF download (placeholder for future implementation)

## Demo Credentials

### Admin Login
- **Email:** admin@hr.com
- **Password:** admin123
- **Role:** Select "Admin" in the segmented control

### Employee Login
- **Email:** employee@hr.com
- **Password:** employee123
- **Role:** Select "Employee" in the segmented control

## Project Structure

```
hr/
├── lib/
│   ├── main.dart                           # App entry point with routing
│   ├── models/
│   │   ├── user.dart                       # User model
│   │   ├── user_role.dart                  # UserRole enum
│   │   ├── employee.dart                   # Employee model
│   │   ├── leave_request.dart              # Leave request model
│   │   ├── task.dart                       # Task model
│   │   ├── attendance.dart                 # Attendance model
│   │   ├── payslip.dart                    # Payslip model
│   │   └── department.dart                 # Department model
│   ├── providers/
│   │   └── auth_provider.dart              # Authentication state management
│   ├── screens/
│   │   ├── login_screen.dart               # Login UI with role selector
│   │   ├── admin_dashboard.dart            # Admin dashboard
│   │   ├── employee_dashboard.dart         # Employee dashboard
│   │   ├── employee_management_screen.dart # Employee CRUD operations
│   │   ├── leave_management_screen.dart    # Admin leave approval
│   │   ├── apply_leave_screen.dart         # Employee leave application
│   │   ├── my_tasks_screen.dart            # Employee task management
│   │   ├── my_attendance_screen.dart       # Employee attendance tracking
│   │   └── payslips_screen.dart            # Employee payslip viewing
│   ├── services/
│   │   ├── auth_service.dart               # Authentication logic
│   │   ├── employee_service.dart           # Employee data management
│   │   ├── leave_service.dart              # Leave request management
│   │   ├── task_service.dart               # Task management
│   │   ├── attendance_service.dart         # Attendance tracking
│   │   └── payslip_service.dart            # Payslip management
│   └── utils/                              # Utility functions
└── pubspec.yaml                            # Dependencies
```

## Dependencies Used

- **provider** (^6.1.5+1) - State management
- **shared_preferences** (^2.5.3) - Local storage for authentication persistence
- **intl** (^0.20.2) - Date formatting and internationalization

## How to Run

1. Navigate to the hr directory:
   ```bash
   cd hr
   ```

2. Get dependencies (already done):
   ```bash
   flutter pub get
   ```

3. Run on Chrome:
   ```bash
   flutter run -d chrome
   ```

4. Run on other platforms:
   ```bash
   flutter run -d macos      # macOS
   flutter run -d ios        # iOS Simulator
   flutter run -d android    # Android Emulator
   ```

## Key Features

### Authentication Flow
1. App checks for existing session on startup
2. If logged in, redirects to appropriate dashboard based on role
3. If not logged in, shows login screen
4. After successful login, navigates to role-specific dashboard
5. Logout clears session and returns to login screen

### State Management
- Uses Provider pattern for reactive state management
- AuthProvider manages authentication state globally
- UI automatically updates when auth state changes

### Security Notes
⚠️ **Important:** This is a demo application with mock authentication. In production:
- Replace mock credentials with real backend API
- Implement proper password hashing
- Add JWT or OAuth authentication
- Implement secure token storage
- Add API error handling
- Implement proper session management

## Next Steps / Future Enhancements

### Completed Features ✅
- ✅ Employee management (CRUD operations)
- ✅ Leave management system
- ✅ Attendance tracking
- ✅ Payroll/Payslip viewing
- ✅ Task management

### Future Enhancements 🔜
- Department management
- Reports and analytics
- Team directory
- Notifications system
- Profile management
- Settings and preferences
- Real backend API integration
- PDF generation for payslips
- Email notifications
- Advanced reporting and charts
- Performance reviews
- Document management
- Chat/messaging system

## Testing

To test the app:
1. Launch the app
2. Try logging in with both Admin and Employee credentials
3. Verify role-based dashboard access
4. Test logout functionality
5. Verify persistent login (close and reopen app)

## Support

For any issues or questions, refer to:
- Flutter documentation: https://docs.flutter.dev/
- Provider package: https://pub.dev/packages/provider
- SharedPreferences: https://pub.dev/packages/shared_preferences

