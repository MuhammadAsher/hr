# HR Management App - User Guide

## Getting Started

### Login
1. Open the app - you'll see the login screen
2. Select your role using the segmented control (Admin or Employee)
3. Enter your credentials:
   - **Admin**: admin@hr.com / admin123
   - **Employee**: employee@hr.com / employee123
4. Click "Login"

## Admin Features

### Dashboard Overview
After logging in as Admin, you'll see:
- Welcome card with your profile
- Statistics cards showing:
  - Total Employees (45)
  - Departments (8)
  - Pending Leaves (12)
  - Active Projects (6)
- Quick action buttons for main features

### Managing Employees

#### View All Employees
1. Click "Manage Employees" from the dashboard
2. You'll see a list of all employees with:
   - Name, position, and department
   - Search bar at the top
   - Three-dot menu for actions

#### Search Employees
1. Type in the search bar
2. Search works across: name, email, department, position
3. Results update in real-time

#### Add New Employee
1. Click the "+" icon in the top-right
2. Fill in the form:
   - Full Name (required)
   - Email (required, must be valid)
   - Phone (required)
   - Department (dropdown)
   - Position (required)
   - Salary (required, numbers only)
3. Click "Add Employee"

#### Edit Employee
1. Click the three-dot menu on any employee
2. Select "Edit"
3. Update the information
4. Click "Update Employee"

#### View Employee Details
1. Click the three-dot menu on any employee
2. Select "View Details"
3. See complete employee information in a dialog

#### Delete Employee
1. Click the three-dot menu on any employee
2. Select "Delete"
3. Confirm the deletion

### Managing Leave Requests

#### View Leave Requests
1. Click "Approve Leave Requests" from the dashboard
2. You'll see all leave requests with status chips

#### Filter Requests
1. Use the filter chips at the top:
   - All
   - Pending
   - Approved
   - Rejected
2. Click any chip to filter

#### Review Leave Request
1. Click on any leave request to expand it
2. View details:
   - Employee name
   - Leave type
   - Start and end dates
   - Number of days
   - Reason
   - Request date

#### Approve/Reject Leave
1. Expand a pending leave request
2. Click "Approve" (green button) or "Reject" (red button)
3. The status updates immediately

## Employee Features

### Dashboard Overview
After logging in as Employee, you'll see:
- Welcome card with your profile
- Personal statistics:
  - Leave Balance (15 days)
  - Attendance (95%)
  - Tasks (8)
  - Projects (3)
- Quick action buttons

### Applying for Leave

#### Submit Leave Request
1. Click "Apply for Leave" from the dashboard
2. Fill in the form:
   - Select leave type (dropdown)
   - Pick start date (calendar)
   - Pick end date (calendar)
   - Enter reason (text area)
3. See automatic calculation of total days
4. Click "Submit Request"

#### View My Leave Requests
1. Scroll down on the Apply Leave screen
2. See all your submitted requests
3. Check status: Pending, Approved, or Rejected

### Viewing Payslips

#### Access Payslips
1. Click "View Payslips" from the dashboard
2. See list of all monthly payslips

#### View Payslip Details
1. Click on any payslip
2. A detailed bottom sheet opens showing:
   - Employee information
   - Basic salary
   - Allowances breakdown (Housing, Transport, Medical)
   - Deductions breakdown (Tax, Insurance, Provident Fund)
   - Gross salary
   - Net salary (highlighted in green)
3. Click "Download PDF" (placeholder for future feature)

### Tracking Attendance

#### View Attendance Stats
1. Click "My Attendance" from the dashboard
2. See your attendance rate percentage
3. View statistics:
   - Present days
   - Leave days
   - Half days

#### View Attendance History
1. Scroll down to see attendance records
2. Each record shows:
   - Date
   - Check-in and check-out times
   - Working hours
   - Status (Present, Leave, Half Day, Absent)
3. Records are sorted by most recent first

### Managing Tasks

#### View Task Statistics
1. Click "My Tasks" from the dashboard
2. See task counts at the top:
   - Todo
   - In Progress
   - Done

#### Filter Tasks
1. Use filter chips to view:
   - All tasks
   - Todo only
   - In Progress only
   - Completed only

#### View Task Details
1. Click on any task to expand it
2. See:
   - Title and description
   - Due date
   - Priority (High/Medium/Low)
   - Assigned by
   - Current status
   - Overdue indicator (if applicable)

#### Update Task Status
1. Expand a task
2. Click on status chips:
   - Todo
   - In Progress
   - Completed
3. Status updates immediately

## Common Features

### Logout
1. Click the logout icon (top-right) in any dashboard
2. You'll be returned to the login screen
3. Your session is cleared

### Navigation
- Use the back arrow to return to the dashboard
- All screens have clear navigation
- Bottom sheets can be dismissed by swiping down

## Tips & Tricks

### For Admins
- Use the search feature to quickly find employees
- Filter leave requests by status to focus on pending items
- Check employee details before making changes
- The system shows confirmation dialogs for destructive actions

### For Employees
- Submit leave requests well in advance
- Check your attendance regularly
- Update task status as you progress
- Review payslips each month for accuracy
- Keep track of your leave balance

## Data Notes

⚠️ **Important**: This is a demo application with mock data:
- All data is stored in memory
- Data resets when you restart the app
- No real backend connection
- Perfect for testing and demonstration

## Troubleshooting

### Can't Login?
- Make sure you selected the correct role (Admin/Employee)
- Check that email and password match exactly
- Credentials are case-sensitive

### Features Not Working?
- Try hot reload (press 'r' in terminal)
- Restart the app if needed
- Check browser console for errors

### Data Not Saving?
- Remember: this is a demo with mock data
- Data persists only during the current session
- Authentication state is saved locally

## Keyboard Shortcuts (Development)

When running in debug mode:
- `r` - Hot reload
- `R` - Hot restart
- `q` - Quit app
- `h` - Help

## Support

For issues or questions:
- Check the README_FEATURES.md for feature documentation
- Review the code in the lib/ directory
- All services use mock data for easy testing

