class Employee {
  final String id;
  final String name;
  final String email;
  final String department;
  final String position;
  final String phone;
  final DateTime joinDate;
  final double salary;
  final String status; // Active, On Leave, Terminated

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.position,
    required this.phone,
    required this.joinDate,
    required this.salary,
    this.status = 'Active',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'position': position,
      'phone': phone,
      'joinDate': joinDate.toIso8601String(),
      'salary': salary,
      'status': status,
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      department: json['department'] as String,
      position: json['position'] as String,
      phone: json['phone'] as String,
      joinDate: DateTime.parse(json['joinDate'] as String),
      salary: (json['salary'] as num).toDouble(),
      status: json['status'] as String? ?? 'Active',
    );
  }

  // Factory constructor for API JSON (with different field names)
  factory Employee.fromApiJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      department: json['department'] as String,
      position: json['position'] as String,
      phone: json['phone'] as String? ?? '',
      joinDate: DateTime.parse(json['join_date'] ?? json['joinDate'] as String),
      salary: double.parse(json['salary'].toString()),
      status: _capitalizeStatus(json['status'] as String? ?? 'active'),
    );
  }

  // Helper method to capitalize status
  static String _capitalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'on_leave':
        return 'On Leave';
      case 'terminated':
        return 'Terminated';
      default:
        return 'Active';
    }
  }

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? position,
    String? phone,
    DateTime? joinDate,
    double? salary,
    String? status,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      salary: salary ?? this.salary,
      status: status ?? this.status,
    );
  }
}
