class Task {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String assignedBy;
  final DateTime dueDate;
  final String priority; // Low, Medium, High
  final String status; // Todo, In Progress, Completed
  final DateTime createdDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedBy,
    required this.dueDate,
    this.priority = 'Medium',
    this.status = 'Todo',
    required this.createdDate,
  });

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && status != 'Completed';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'status': status,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      assignedTo: json['assignedTo'] as String,
      assignedBy: json['assignedBy'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: json['priority'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'Todo',
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo,
    String? assignedBy,
    DateTime? dueDate,
    String? priority,
    String? status,
    DateTime? createdDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy ?? this.assignedBy,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}

