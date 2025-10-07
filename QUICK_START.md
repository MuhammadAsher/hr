# HR Management App - Quick Start Guide

## 🚀 Get Started in 3 Steps

### 1. Run the App
```bash
cd hr
flutter run -d chrome
```

### 2. Login
**Admin Account:**
- Email: `admin@hr.com`
- Password: `admin123`
- Role: Select "Admin"

**Employee Account:**
- Email: `employee@hr.com`
- Password: `employee123`
- Role: Select "Employee"

### 3. Explore Features!

## 🎯 Quick Feature Tour

### As Admin (admin@hr.com)

#### 1. Manage Employees (30 seconds)
1. Click "Manage Employees"
2. Click "+" to add new employee
3. Fill form and save
4. Try searching for employees
5. Click three-dot menu to edit/delete

#### 2. Approve Leave Requests (20 seconds)
1. Click "Approve Leave Requests"
2. See pending requests
3. Expand any request
4. Click "Approve" or "Reject"

### As Employee (employee@hr.com)

#### 1. Apply for Leave (30 seconds)
1. Click "Apply for Leave"
2. Select leave type
3. Pick dates
4. Enter reason
5. Submit

#### 2. View Payslips (15 seconds)
1. Click "View Payslips"
2. Click any month
3. See detailed breakdown

#### 3. Check Attendance (15 seconds)
1. Click "My Attendance"
2. See your attendance rate
3. Scroll to view history

#### 4. Manage Tasks (20 seconds)
1. Click "My Tasks"
2. Expand any task
3. Update status

## 📱 Available Platforms

Run on different platforms:

```bash
# Web
flutter run -d chrome

# macOS
flutter run -d macos

# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android
```

## 🎨 What You'll See

### Admin Dashboard
- 📊 Statistics cards
- 👥 Employee count
- 📋 Pending leaves
- 🎯 Quick actions

### Employee Dashboard
- 📅 Leave balance
- ✅ Attendance rate
- 📝 Task count
- 💰 Quick access to payslips

## 🔥 Hot Reload

While the app is running:
- Press `r` for hot reload (instant updates)
- Press `R` for hot restart (full restart)
- Press `q` to quit

## 📖 Need More Help?

- **Features**: See `README_FEATURES.md`
- **User Guide**: See `USER_GUIDE.md`
- **Implementation**: See `IMPLEMENTATION_SUMMARY.md`

## 🎯 Try These Workflows

### Workflow 1: Complete Leave Request Process
1. Login as Employee
2. Apply for leave
3. Logout
4. Login as Admin
5. Approve the leave request
6. Logout
7. Login as Employee
8. See approved status

### Workflow 2: Employee Management
1. Login as Admin
2. Add new employee
3. Search for the employee
4. Edit employee details
5. View employee details
6. Delete employee (optional)

### Workflow 3: Task Management
1. Login as Employee
2. Go to "My Tasks"
3. See tasks in different states
4. Update a task from "Todo" to "In Progress"
5. Complete a task

## 💡 Pro Tips

1. **Search is powerful** - Try searching employees by name, email, or department
2. **Filters work instantly** - Use filter chips to quickly find what you need
3. **Expand for details** - Click on cards to see more information
4. **Status colors matter** - Green = good, Orange = pending, Red = issues
5. **Session persists** - Close and reopen - you'll stay logged in

## 🐛 Troubleshooting

**App won't start?**
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

**Login not working?**
- Check you selected the right role (Admin/Employee)
- Credentials are case-sensitive
- Make sure email includes @hr.com

**Features not responding?**
- Press `r` for hot reload
- Press `R` for hot restart
- Check browser console for errors

## 📊 Mock Data Overview

The app comes with pre-loaded mock data:
- **5 Employees** in various departments
- **3 Leave Requests** (1 approved, 2 pending)
- **4 Tasks** assigned to employee
- **30 Days** of attendance records
- **6 Months** of payslips

All data is stored in memory and resets on app restart.

## 🎓 Learning Path

**Beginner** (5 minutes)
1. Login as both roles
2. Navigate dashboards
3. View statistics

**Intermediate** (15 minutes)
1. Add/edit employees
2. Submit leave request
3. Approve leave request
4. Update task status

**Advanced** (30 minutes)
1. Complete full workflows
2. Test all features
3. Explore code structure
4. Customize mock data

## 🚀 Next Steps

After exploring the app:
1. Review the code in `lib/` directory
2. Check out the models in `lib/models/`
3. Explore services in `lib/services/`
4. Customize the UI in `lib/screens/`
5. Add your own features!

## 📞 Support

Questions? Check these files:
- `README_FEATURES.md` - Feature documentation
- `USER_GUIDE.md` - Detailed user guide
- `IMPLEMENTATION_SUMMARY.md` - Technical details

---

**Ready to start? Run the app and login!** 🎉

```bash
cd hr && flutter run -d chrome
```

