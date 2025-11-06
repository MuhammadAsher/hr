class Department {
  final String id;
  final String name;
  final String description;
  final String? managerId; // Optional - manager can be null
  final String? managerName; // Optional - manager can be null
  final int employeeCount;

  Department({
    required this.id,
    required this.name,
    required this.description,
    this.managerId,
    this.managerName,
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      managerId: json['managerId']?.toString(),
      managerName: json['managerName']?.toString(),
      employeeCount: (json['employeeCount'] is int) 
          ? json['employeeCount'] as int
          : (json['employeeCount'] is String)
              ? int.tryParse(json['employeeCount'] as String) ?? 0
              : 0,
    );
  }

  Department copyWith({
    String? id,
    String? name,
    String? description,
    String? managerId,
    String? managerName,
    int? employeeCount,
    bool? clearManagerId,
    bool? clearManagerName,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      managerId: clearManagerId == true ? null : (managerId ?? this.managerId),
      managerName: clearManagerName == true ? null : (managerName ?? this.managerName),
      employeeCount: employeeCount ?? this.employeeCount,
    );
  }
}

