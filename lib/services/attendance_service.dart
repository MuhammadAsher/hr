import '../models/attendance.dart';

class AttendanceService {
  final List<Attendance> _attendanceRecords = [];

  AttendanceService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Generate attendance records for the last 30 days for employee ID '2'
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      
      // Skip weekends
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        continue;
      }

      // Randomly assign some absences and half days
      String status = 'Present';
      DateTime? checkIn;
      DateTime? checkOut;

      if (i % 10 == 0) {
        status = 'Leave';
      } else if (i % 7 == 0) {
        status = 'Half Day';
        checkIn = DateTime(date.year, date.month, date.day, 9, 0);
        checkOut = DateTime(date.year, date.month, date.day, 13, 30);
      } else {
        checkIn = DateTime(date.year, date.month, date.day, 9, 0 + (i % 30));
        checkOut = DateTime(date.year, date.month, date.day, 17, 30 + (i % 45));
      }

      _attendanceRecords.add(
        Attendance(
          id: 'att_${i + 1}',
          employeeId: '2',
          date: date,
          checkIn: checkIn,
          checkOut: checkOut,
          status: status,
        ),
      );
    }
  }

  Future<List<Attendance>> getAttendanceByEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _attendanceRecords
        .where((att) => att.employeeId == employeeId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<Attendance>> getAttendanceByDateRange(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _attendanceRecords.where((att) {
      return att.employeeId == employeeId &&
          att.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          att.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<Map<String, dynamic>> getAttendanceStats(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final records = _attendanceRecords.where((att) => att.employeeId == employeeId).toList();
    
    final totalDays = records.length;
    final presentDays = records.where((att) => att.status == 'Present').length;
    final absentDays = records.where((att) => att.status == 'Absent').length;
    final leaveDays = records.where((att) => att.status == 'Leave').length;
    final halfDays = records.where((att) => att.status == 'Half Day').length;
    
    final attendancePercentage = totalDays > 0 
        ? ((presentDays + halfDays * 0.5) / totalDays * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'totalDays': totalDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'leaveDays': leaveDays,
      'halfDays': halfDays,
      'attendancePercentage': attendancePercentage,
    };
  }

  Future<bool> markAttendance(Attendance attendance) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _attendanceRecords.add(attendance);
    return true;
  }
}

