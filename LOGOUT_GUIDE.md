# 🚪 Logout & Navigation Guide

## How to Logout from Each Dashboard

### 🌟 **Super Admin Dashboard**

**Location:** Top-right corner of the screen

**Steps:**
1. Click the **Account Icon** (👤) in the top-right corner
2. A menu will appear
3. Click **"Logout"** (with red logout icon)
4. You'll be automatically redirected to the Login Screen

**Visual:**
```
┌─────────────────────────────────────────┐
│ Platform Administration    🔄  👤      │ ← Click here
│                                         │
│  ┌──────────────────┐                  │
│  │ Logout 🚪        │ ← Then click     │
│  └──────────────────┘                  │
└─────────────────────────────────────────┘
```

**Code Location:**
<augment_code_snippet path="lib/screens/super_admin_dashboard.dart" mode="EXCERPT">
```dart
PopupMenuButton<String>(
  icon: const Icon(Icons.account_circle),
  onSelected: (value) async {
    if (value == 'logout') {
      await authProvider.logout();
    }
  },
)
```
</augment_code_snippet>

---

### 🏢 **Admin Dashboard (Organization)**

**Location:** Top-right corner of the screen

**Steps:**
1. Click the **Logout Icon** (🚪) in the top-right corner
2. You'll be automatically redirected to the Login Screen

**Visual:**
```
┌─────────────────────────────────────────┐
│ Admin Dashboard                    🚪   │ ← Click here
│                                         │
│  Welcome back, Admin User               │
│  admin@hr.com                           │
└─────────────────────────────────────────┘
```

**Code Location:**
<augment_code_snippet path="lib/screens/admin_dashboard.dart" mode="EXCERPT">
```dart
IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () async {
    await authProvider.logout();
  },
)
```
</augment_code_snippet>

---

### 👤 **Employee Dashboard**

**Location:** Top-right corner of the screen

**Steps:**
1. Click the **Logout Icon** (🚪) in the top-right corner
2. You'll be automatically redirected to the Login Screen

**Visual:**
```
┌─────────────────────────────────────────┐
│ Employee Dashboard                 🚪   │ ← Click here
│                                         │
│  Welcome back, Employee User            │
│  employee@hr.com                        │
└─────────────────────────────────────────┘
```

**Code Location:**
<augment_code_snippet path="lib/screens/employee_dashboard.dart" mode="EXCERPT">
```dart
IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () async {
    await authProvider.logout();
  },
)
```
</augment_code_snippet>

---

## 🔄 Complete Navigation Flow

### **Switching Between Accounts**

To test different user types:

1. **Logout from current dashboard**
   - Click logout button/menu
   
2. **Login Screen appears**
   - Enter different credentials
   - Select appropriate role
   
3. **Login with new account**
   - Automatically routed to correct dashboard

### **Example: Testing All Three User Types**

#### Step 1: Test Super Admin
```
1. Login: superadmin@hrplatform.com / super123 (Admin)
2. Explore Super Admin Dashboard
3. Click Account Icon (👤) → Logout
```

#### Step 2: Test Organization Admin
```
1. Login: admin@hr.com / admin123 (Admin)
2. Explore Admin Dashboard
3. Click Logout Icon (🚪)
```

#### Step 3: Test Employee
```
1. Login: employee@hr.com / employee123 (Employee)
2. Explore Employee Dashboard
3. Click Logout Icon (🚪)
```

#### Step 4: Test Different Organization
```
1. Login: admin@globalmarketing.com / admin123 (Admin)
2. Notice different data (Global Marketing vs Tech Solutions)
3. Click Logout Icon (🚪)
```

---

## 🔐 What Happens When You Logout?

### **Technical Process:**

1. **User clicks logout**
   ```dart
   await authProvider.logout();
   ```

2. **AuthProvider clears session**
   - Removes user from local storage
   - Sets currentUser to null
   - Sets isAuthenticated to false

3. **AuthWrapper detects change**
   - Listens to AuthProvider
   - Detects isAuthenticated = false

4. **Automatic navigation**
   - Shows Login Screen
   - No manual navigation needed

### **Code Flow:**

```
User clicks Logout
    ↓
authProvider.logout() called
    ↓
SharedPreferences.remove('current_user')
    ↓
AuthProvider notifies listeners
    ↓
AuthWrapper (in main.dart) rebuilds
    ↓
Checks: isAuthenticated = false
    ↓
Shows Login Screen
```

---

## 🎯 Quick Reference

| Dashboard | Logout Method | Icon | Location |
|-----------|---------------|------|----------|
| **Super Admin** | Menu → Logout | 👤 → 🚪 | Top-right |
| **Admin** | Direct Button | 🚪 | Top-right |
| **Employee** | Direct Button | 🚪 | Top-right |

---

## 💡 Tips

### **Testing Multiple Accounts:**
- Use logout to quickly switch between accounts
- No need to restart the app
- All data is preserved (mock data)

### **Data Isolation Testing:**
1. Login as Tech Solutions admin
2. Note the employees shown
3. Logout
4. Login as Global Marketing admin
5. Verify different employees
6. **Result:** Data isolation confirmed! ✅

### **Role Testing:**
1. Login as admin (any organization)
2. See admin features
3. Logout
4. Login as employee (same organization)
5. See limited employee features
6. **Result:** Role-based access confirmed! ✅

---

## 🚨 Troubleshooting

### **Can't find logout button?**
- **Super Admin:** Look for account icon (👤) in top-right
- **Admin/Employee:** Look for logout icon (🚪) in top-right

### **Logout doesn't work?**
- Check if you're connected to the internet (not required for demo)
- Try clicking the button again
- Restart the app if needed

### **Stuck on a screen?**
- All dashboards have logout functionality
- Use the logout button to return to login screen
- No need to use device back button

---

## 📱 Mobile vs Desktop

### **Mobile (Flutter App):**
- Logout buttons in AppBar (top-right)
- Touch to logout
- Automatic navigation

### **Web (if deployed):**
- Same logout buttons
- Click to logout
- Browser back button won't work (use logout)

---

## ✅ Summary

**All dashboards now have logout functionality:**

✅ **Super Admin Dashboard** - Account menu with logout option  
✅ **Admin Dashboard** - Direct logout button  
✅ **Employee Dashboard** - Direct logout button  

**Navigation is automatic:**
- Logout → Login Screen
- Login → Appropriate Dashboard
- No manual navigation needed

**You can now:**
- ✅ Test all user types easily
- ✅ Switch between accounts quickly
- ✅ Verify data isolation
- ✅ Test role-based access
- ✅ Return to login anytime

---

**The multi-tenant system is fully functional with complete navigation!** 🎉

