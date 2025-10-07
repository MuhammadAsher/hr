class Attendance {
  final String id;
  final String employeeId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status; // Present, Absent, Half Day, Leave
  final String? notes;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.status = 'Present',
    this.notes,
  });

  String get workingHours {
    if (checkIn != null && checkOut != null) {
      final duration = checkOut!.difference(checkIn!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
    return 'N/A';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'checkIn': checkIn?.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      date: DateTime.parse(json['date'] as String),
      checkIn: json['checkIn'] != null
          ? DateTime.parse(json['checkIn'] as String)
          : null,
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'] as String)
          : null,
      status: json['status'] as String? ?? 'Present',
      notes: json['notes'] as String?,
    );
  }
}

