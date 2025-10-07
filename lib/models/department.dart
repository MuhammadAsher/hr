class Department {
  final String id;
  final String name;
  final String description;
  final String managerId;
  final String managerName;
  final int employeeCount;

  Department({
    required this.id,
    required this.name,
    required this.description,
    required this.managerId,
    required this.managerName,
    this.employeeCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'managerId': managerId,
      'managerName': managerName,
      'employeeCount': employeeCount,
    };
  }

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      managerId: json['managerId'] as String,
      managerName: json['managerName'] as String,
      employeeCount: json['employeeCount'] as int? ?? 0,
    );
  }

  Department copyWith({
    String? id,
    String? name,
    String? description,
    String? managerId,
    String? managerName,
    int? employeeCount,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      employeeCount: employeeCount ?? this.employeeCount,
    );
  }
}

