import 'user_role.dart';

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String organizationId; // Link to organization
  final bool isSuperAdmin; // Platform super admin (for your company)

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.organizationId,
    this.isSuperAdmin = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'organizationId': organizationId,
      'isSuperAdmin': isSuperAdmin,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.employee,
      ),
      organizationId: json['organizationId'] as String? ?? '',
      isSuperAdmin: json['isSuperAdmin'] as bool? ?? false,
    );
  }
}
