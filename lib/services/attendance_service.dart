import '../models/attendance.dart';
import 'api_client.dart';

class AttendanceService {
  final ApiClient _apiClient = ApiClient();

  // Get attendance records for current user or specific employee
  Future<List<Attendance>> getAttendanceRecords({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (employeeId != null) queryParams['employeeId'] = employeeId;
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get(
        '/attendance',
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        final responseData = response.data['data'];
        final List<dynamic> attendance = responseData['attendance'] ?? [];
        return attendance.map((json) => Attendance.fromJson(json)).toList();
      } else {
        throw Exception(
          response.message ?? 'Failed to fetch attendance records',
        );
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockAttendanceData(employeeId ?? '2');
    }
  }

  // Clock in functionality
  Future<bool> clockIn({String? location, String? notes}) async {
    try {
      final body = <String, dynamic>{};
      if (location != null) body['location'] = location;
      if (notes != null) body['notes'] = notes;

      final response = await _apiClient.post(
        '/attendance/clock-in',
        body: body,
      );
      return response.isSuccess;
    } catch (e) {
      print('Clock in error: $e');
      return false;
    }
  }

  // Clock out functionality
  Future<bool> clockOut({String? location, String? notes}) async {
    try {
      final body = <String, dynamic>{};
      if (location != null) body['location'] = location;
      if (notes != null) body['notes'] = notes;

      final response = await _apiClient.post(
        '/attendance/clock-out',
        body: body,
      );
      return response.isSuccess;
    } catch (e) {
      print('Clock out error: $e');
      return false;
    }
  }

  // Get current attendance status
  Future<Map<String, dynamic>?> getCurrentStatus() async {
    try {
      final response = await _apiClient.get('/attendance/status');
      if (response.isSuccess) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Get status error: $e');
      return null;
    }
  }

  // Get attendance summary
  Future<Map<String, dynamic>?> getAttendanceSummary() async {
    try {
      final response = await _apiClient.get('/attendance/summary');
      if (response.isSuccess) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Get summary error: $e');
      return null;
    }
  }

  // Fallback mock data method
  List<Attendance> _getMockAttendanceData(String employeeId) {
    final List<Attendance> mockRecords = [];
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));

      // Skip weekends
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        continue;
      }

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

      mockRecords.add(
        Attendance(
          id: 'att_${i + 1}',
          employeeId: employeeId,
          date: date,
          checkIn: checkIn,
          checkOut: checkOut,
          status: status,
        ),
      );
    }
    return mockRecords;
  }

  // Legacy method - now uses API
  Future<List<Attendance>> getAttendanceByEmployee(String employeeId) async {
    return await getAttendanceRecords(employeeId: employeeId, limit: 100);
  }

  // Get attendance by date range
  Future<List<Attendance>> getAttendanceByDateRange(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await getAttendanceRecords(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
      limit: 100,
    );
  }

  // Get attendance statistics
  Future<Map<String, dynamic>> getAttendanceStats(String employeeId) async {
    try {
      // Try to get from API summary first
      final summary = await getAttendanceSummary();
      if (summary != null) {
        return summary;
      }

      // Fallback to calculating from records
      final records = await getAttendanceByEmployee(employeeId);
      final totalDays = records.length;
      final presentDays = records
          .where((att) => att.status == 'Present')
          .length;
      final absentDays = records.where((att) => att.status == 'Absent').length;
      final leaveDays = records.where((att) => att.status == 'Leave').length;
      final halfDays = records.where((att) => att.status == 'Half Day').length;

      final attendancePercentage = totalDays > 0
          ? ((presentDays + halfDays * 0.5) / totalDays * 100).toStringAsFixed(
              1,
            )
          : '0.0';

      return {
        'totalDays': totalDays,
        'presentDays': presentDays,
        'absentDays': absentDays,
        'leaveDays': leaveDays,
        'halfDays': halfDays,
        'attendancePercentage': attendancePercentage,
      };
    } catch (e) {
      print('Get attendance stats error: $e');
      return {
        'totalDays': 0,
        'presentDays': 0,
        'absentDays': 0,
        'leaveDays': 0,
        'halfDays': 0,
        'attendancePercentage': '0.0',
      };
    }
  }

  // Mark attendance (legacy method - now uses clock in/out)
  Future<bool> markAttendance(Attendance attendance) async {
    // This method is deprecated - use clockIn/clockOut instead
    print('markAttendance is deprecated - use clockIn/clockOut methods');
    return false;
  }
}
