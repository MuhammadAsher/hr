class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // Pending, Approved, Rejected
  final DateTime requestDate;
  final String? approvedBy;
  final DateTime? approvedDate;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = 'Pending',
    required this.requestDate,
    this.approvedBy,
    this.approvedDate,
  });

  int get daysCount {
    return endDate.difference(startDate).inDays + 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'requestDate': requestDate.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedDate': approvedDate?.toIso8601String(),
    };
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      leaveType: json['leaveType'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      reason: json['reason'] as String,
      status: json['status'] as String? ?? 'Pending',
      requestDate: DateTime.parse(json['requestDate'] as String),
      approvedBy: json['approvedBy'] as String?,
      approvedDate: json['approvedDate'] != null
          ? DateTime.parse(json['approvedDate'] as String)
          : null,
    );
  }

  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? status,
    DateTime? requestDate,
    String? approvedBy,
    DateTime? approvedDate,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedDate: approvedDate ?? this.approvedDate,
    );
  }
}

