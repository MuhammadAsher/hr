# 🔐 Login Credentials for Testing

## Multi-Tenant System Test Accounts

### 🌟 Super Admin (Platform Administrator)
**Your company's platform administrator who can manage all organizations**

- **Email:** `superadmin@hrplatform.com`
- **Password:** `super123`
- **Role:** Admin
- **Access:** Super Admin Dashboard
- **Can Do:**
  - View all organizations
  - Manage organizations (activate/deactivate)
  - View platform statistics
  - Add new organizations
  - Monitor revenue and subscriptions

---

### 🏢 Organization 1: Tech Solutions Inc. (ORG001)

#### Admin Account
- **Email:** `admin@hr.com`
- **Password:** `admin123`
- **Role:** Admin
- **Organization:** Tech Solutions Inc.
- **Subscription:** Premium Plan
- **Access:** Organization Admin Dashboard
- **Can Do:**
  - Manage employees (only from Tech Solutions)
  - Handle leave requests
  - Manage departments
  - View reports and analytics
  - Generate PDFs
  - Send email notifications

#### Employee Account
- **Email:** `employee@hr.com`
- **Password:** `employee123`
- **Role:** Employee
- **Organization:** Tech Solutions Inc.
- **Access:** Employee Dashboard
- **Can Do:**
  - Apply for leave
  - View own attendance
  - View own payslips
  - View team directory
  - Manage assigned tasks

---

### 🏢 Organization 2: Global Marketing Agency (ORG002)

#### Admin Account
- **Email:** `admin@globalmarketing.com`
- **Password:** `admin123`
- **Role:** Admin
- **Organization:** Global Marketing Agency
- **Subscription:** Basic Plan
- **Access:** Organization Admin Dashboard
- **Can Do:**
  - Manage employees (only from Global Marketing)
  - Handle leave requests
  - Manage departments
  - View reports and analytics

#### Employee Account
- **Email:** `employee@globalmarketing.com`
- **Password:** `employee123`
- **Role:** Employee
- **Organization:** Global Marketing Agency
- **Access:** Employee Dashboard
- **Can Do:**
  - Apply for leave
  - View own attendance
  - View own payslips
  - View team directory
  - Manage assigned tasks

---

## 🧪 Testing Scenarios

### Scenario 1: Super Admin Access
1. Login with `superadmin@hrplatform.com` / `super123` (Role: Admin)
2. You'll see the **Super Admin Dashboard**
3. View all organizations on the platform
4. See platform statistics (total orgs, revenue, etc.)
5. Manage organizations (activate/deactivate)

### Scenario 2: Organization Admin - Tech Solutions
1. Login with `admin@hr.com` / `admin123` (Role: Admin)
2. You'll see the **Admin Dashboard** for Tech Solutions Inc.
3. All data shown is ONLY for Tech Solutions (ORG001)
4. Cannot see Global Marketing's data

### Scenario 3: Organization Admin - Global Marketing
1. Login with `admin@globalmarketing.com` / `admin123` (Role: Admin)
2. You'll see the **Admin Dashboard** for Global Marketing Agency
3. All data shown is ONLY for Global Marketing (ORG002)
4. Cannot see Tech Solutions' data

### Scenario 4: Employee Access - Tech Solutions
1. Login with `employee@hr.com` / `employee123` (Role: Employee)
2. You'll see the **Employee Dashboard**
3. Can only see own data and team from Tech Solutions

### Scenario 5: Employee Access - Global Marketing
1. Login with `employee@globalmarketing.com` / `employee123` (Role: Employee)
2. You'll see the **Employee Dashboard**
3. Can only see own data and team from Global Marketing

### Scenario 6: Data Isolation Test
1. Login as Tech Solutions admin
2. Note the employees/data shown
3. Logout
4. Login as Global Marketing admin
5. Verify completely different set of employees/data
6. **Result:** Each organization's data is completely isolated!

---

## 🎯 Key Features to Test

### As Super Admin:
- ✅ View platform overview
- ✅ See all registered organizations
- ✅ View total revenue from subscriptions
- ✅ Search organizations
- ✅ Activate/deactivate organizations
- ✅ View organization details
- ✅ Add new organizations

### As Organization Admin:
- ✅ Manage employees (only from your org)
- ✅ Department management
- ✅ Leave request approval
- ✅ Attendance tracking
- ✅ Reports & analytics
- ✅ PDF generation
- ✅ Email notifications
- ✅ Advanced reporting

### As Employee:
- ✅ Apply for leave
- ✅ View attendance
- ✅ View payslips
- ✅ Team directory
- ✅ Task management

---

## 📊 Organization Details

### Tech Solutions Inc. (ORG001)
- **Industry:** Technology
- **Plan:** Premium ($149.99/month)
- **Employee Limit:** 200
- **Status:** Active
- **Registered:** January 15, 2023

### Global Marketing Agency (ORG002)
- **Industry:** Marketing
- **Plan:** Basic ($49.99/month)
- **Employee Limit:** 50
- **Status:** Active
- **Registered:** March 20, 2023

---

## 🚀 Quick Start

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Test Super Admin:**
   - Login: `superadmin@hrplatform.com` / `super123` (Admin role)
   - Explore platform management features

3. **Test Organization Isolation:**
   - Login as Tech Solutions admin
   - Note the data
   - Logout and login as Global Marketing admin
   - Verify different data set

4. **Test Employee Experience:**
   - Login as employee from either organization
   - Test leave application, attendance viewing, etc.

---

## 💡 Tips

- **Role Selection:** Make sure to select the correct role (Admin/Employee) during login
- **Data Isolation:** Each organization only sees their own data
- **Super Admin:** Has special access to manage the entire platform
- **Logout:** Use the logout button to switch between different accounts

---

## 🔄 Adding New Organizations

As Super Admin:
1. Login to Super Admin Dashboard
2. Click "Add Organization" button
3. Fill in organization details
4. Select subscription plan
5. Create admin account for the organization
6. New organization can now login and use the system!

---

**Note:** This is a demo system with mock data. In production, all credentials would be securely hashed and stored in a database with proper authentication mechanisms.

