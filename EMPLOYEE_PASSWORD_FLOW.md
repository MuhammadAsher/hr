# Employee Password & Organization Data Flow

## 📋 Overview
Yeh document explain karta hai ke jab admin employee create karta hai, to password kaise handle hota hai, employee kaise login kar sakta hai, aur organization-scoped data kaise filter hota hai.

---

## 🔐 1. Password Handling (Employee Creation)

### Backend Process (`backend/src/routes/employees.js`)

**Step 1: Default Password Set**
```javascript
const defaultPassword = 'employee123';
```

**Step 2: User Account Creation**
```javascript
const user = await User.create({
  organization_id: organizationId,  // Admin ki organization se link
  email,
  password_hash: defaultPassword,   // Plain password (hash hoga automatically)
  name,
  role: 'employee',
  email_verified: false,
  is_active: true,
}, { transaction });
```

**Step 3: Automatic Password Hashing**
- `User` model mein `beforeCreate` hook hai
- Ye hook automatically password ko **bcrypt** se hash karta hai (12 rounds)
- Plain password database mein store nahi hota, sirf hash store hota hai

```javascript
// backend/src/models/User.js
hooks: {
  beforeCreate: async (user) => {
    if (user.password_hash) {
      user.password_hash = await bcrypt.hash(user.password_hash, 12);
    }
  }
}
```

**Step 4: Success Response**
- Frontend ko success message milta hai:
  - "Employee created successfully with user account. Default password: employee123"
- Admin ko employee ka email aur default password dikhaya jata hai

---

## 🔑 2. Employee Login Flow

### Login Process (`backend/src/routes/auth.js`)

**Step 1: Employee Login Request**
```javascript
POST /api/v1/auth/login
{
  "email": "employee@example.com",
  "password": "employee123",
  "role": "employee"
}
```

**Step 2: User Lookup**
- Database mein user find kiya jata hai by email
- User ka `organization_id` aur `organization` details fetch kiye jate hain
- Password hash database se retrieve hota hai

**Step 3: Password Validation**
```javascript
// backend/src/models/User.js
User.prototype.validatePassword = async function(password) {
  return bcrypt.compare(password, this.password_hash);
};
```
- Plain password (`employee123`) ko stored hash se compare kiya jata hai
- `bcrypt.compare()` secure comparison karta hai

**Step 4: JWT Token Generation**
```javascript
const token = generateToken(user);
// Token includes:
// - userId
// - email
// - role
// - organizationId  ← Important for data filtering
// - isSuperAdmin
```

**Step 5: Login Response**
```json
{
  "status": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "...",
    "user": {
      "id": "uuid",
      "email": "employee@example.com",
      "name": "Employee Name",
      "role": "employee",
      "organizationId": "org-uuid",
      "organizationName": "Organization Name",
      "isSuperAdmin": false
    }
  }
}
```

---

## 🏢 3. Organization-Scoped Data Filtering

### Automatic Data Filtering

**Middleware: `addOrganizationFilter`** (`backend/src/middleware/auth.js`)

```javascript
const addOrganizationFilter = (req, res, next) => {
  // Super admin ko filter ki zarurat nahi
  if (req.user.is_super_admin) {
    return next();
  }
  
  // Employee/Admin ke liye organization filter add karo
  req.organizationFilter = {
    organization_id: req.user.organization_id,  // JWT token se aata hai
  };
  
  next();
};
```

### Example: Employee List API

**Route:**
```javascript
router.get('/', addOrganizationFilter, async (req, res) => {
  const whereClause = { ...req.organizationFilter };  // organization_id automatically add ho jata hai
  
  const employees = await Employee.findAndCountAll({
    where: whereClause,  // Sirf same organization ke employees
    // ...
  });
});
```

**Result:**
- Employee sirf apni organization ke employees dekh sakta hai
- Dusri organization ka data nahi dikhega
- Admin bhi sirf apni organization ka data dekh sakta hai

---

## 🔒 4. Security Features

### Password Security
1. **Hashing**: Passwords bcrypt se hash hote hain (12 rounds)
2. **No Plain Text**: Database mein plain password store nahi hota
3. **Secure Comparison**: `bcrypt.compare()` timing attacks se protect karta hai

### Organization Isolation
1. **JWT Token**: `organizationId` token mein included hota hai
2. **Middleware Filter**: Har request automatically filter hoti hai
3. **Database Level**: `organization_id` foreign key constraint se enforce hota hai

### Access Control
1. **Role-Based**: Employee aur Admin ka role check hota hai
2. **Organization Check**: User sirf apni organization ka data access kar sakta hai
3. **Active Status**: Inactive users login nahi kar sakte

---

## 📱 5. Frontend Flow

### Employee Creation (Admin Side)
1. Admin employee create karta hai
2. Success dialog mein email aur default password dikhaya jata hai:
   ```
   Employee Created Successfully!
   
   Email: employee@example.com
   Default Password: employee123
   
   Note: Employee can reset password from the app.
   ```

### Employee Login (Employee Side)
1. Employee login screen par apna email enter karta hai
2. Default password `employee123` enter karta hai
3. Role "Employee" select karta hai
4. Login successful hone par employee dashboard dikhta hai
5. Employee sirf apni organization ka data dekh sakta hai

### Password Reset
- Employee app se password reset kar sakta hai
- "Forgot Password" feature available hai
- Reset token email par bheja jata hai (future implementation)

---

## 🎯 6. Complete Flow Diagram

```
Admin Creates Employee
    ↓
User Account Created (email, password_hash: "employee123")
    ↓
Password Auto-Hashed (bcrypt, 12 rounds)
    ↓
Employee Record Created (linked to User & Organization)
    ↓
Success: Email + Default Password shown to Admin
    ↓
Employee Logs In (email + "employee123")
    ↓
Password Validated (bcrypt.compare)
    ↓
JWT Token Generated (includes organizationId)
    ↓
Employee Dashboard Loaded
    ↓
All API Requests Auto-Filtered by organizationId
    ↓
Employee Sees Only Their Organization's Data
```

---

## ✅ Summary

1. **Password**: Default password `employee123` automatically hash hota hai
2. **Login**: Employee email + default password se login kar sakta hai
3. **Organization**: Employee automatically apni organization se link hota hai
4. **Data Filtering**: Sab data automatically organization ke basis par filter hota hai
5. **Security**: Passwords secure hain, organization isolation enforce hota hai

---

## 🔧 Testing

### Test Employee Login
1. Admin se employee create karo
2. Employee email aur default password note karo
3. Employee login screen par:
   - Email: `employee@example.com`
   - Password: `employee123`
   - Role: `Employee`
4. Login successful hona chahiye
5. Employee dashboard par sirf apni organization ka data dikhna chahiye

### Test Organization Isolation
1. Do different organizations ke employees create karo
2. Pehle organization ke employee se login karo
3. Employee list check karo - sirf apni organization ke employees dikhne chahiye
4. Dusre organization ke employee se login karo
5. Employee list check karo - ab sirf dusre organization ke employees dikhne chahiye

---

## 📝 Notes

- Default password `employee123` hai, lekin employee app se password reset kar sakta hai
- Organization isolation database level par enforce hota hai
- Super admin sab organizations ka data dekh sakta hai
- Regular admin/employee sirf apni organization ka data dekh sakta hai

