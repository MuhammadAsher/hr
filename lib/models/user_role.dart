enum UserRole {
  admin,
  employee,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.employee:
        return 'Employee';
    }
  }
}

