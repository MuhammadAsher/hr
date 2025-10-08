import '../models/employee.dart';
import '../models/leave_request.dart';
import '../models/attendance.dart';
import '../models/department.dart';
import 'employee_service.dart';
import 'leave_service.dart';
import 'attendance_service.dart';
import 'department_service.dart';

class AnalyticsService {
  final EmployeeService _employeeService = EmployeeService();
  final LeaveService _leaveService = LeaveService();
  final AttendanceService _attendanceService = AttendanceService();
  final DepartmentService _departmentService = DepartmentService();

  // Employee Analytics
  Future<Map<String, dynamic>> getEmployeeAnalytics() async {
    final employees = await _employeeService.getAllEmployees();
    final departments = await _departmentService.getAllDepartments();

    // Department distribution
    final departmentCounts = <String, int>{};
    for (var employee in employees) {
      departmentCounts[employee.department] =
          (departmentCounts[employee.department] ?? 0) + 1;
    }

    // Status distribution
    final statusCounts = <String, int>{};
    for (var employee in employees) {
      statusCounts[employee.status] = (statusCounts[employee.status] ?? 0) + 1;
    }

    // Salary analytics
    final salaries = employees.map((e) => e.salary).toList();
    salaries.sort();

    final averageSalary = salaries.isEmpty
        ? 0.0
        : salaries.reduce((a, b) => a + b) / salaries.length;
    final medianSalary = salaries.isEmpty
        ? 0.0
        : salaries[salaries.length ~/ 2];
    final minSalary = salaries.isEmpty ? 0.0 : salaries.first;
    final maxSalary = salaries.isEmpty ? 0.0 : salaries.last;

    // Tenure analytics
    final now = DateTime.now();
    final tenures = employees
        .map((e) => now.difference(e.joinDate).inDays / 365.25)
        .toList();
    final averageTenure = tenures.isEmpty
        ? 0.0
        : tenures.reduce((a, b) => a + b) / tenures.length;

    return {
      'totalEmployees': employees.length,
      'totalDepartments': departments.length,
      'departmentDistribution': departmentCounts,
      'statusDistribution': statusCounts,
      'salaryAnalytics': {
        'average': averageSalary,
        'median': medianSalary,
        'min': minSalary,
        'max': maxSalary,
      },
      'averageTenure': averageTenure,
    };
  }

  // Leave Analytics
  Future<Map<String, dynamic>> getLeaveAnalytics() async {
    final leaveRequests = await _leaveService.getAllLeaveRequests();

    // Status distribution
    final statusCounts = <String, int>{};
    for (var request in leaveRequests) {
      statusCounts[request.status] = (statusCounts[request.status] ?? 0) + 1;
    }

    // Type distribution
    final typeCounts = <String, int>{};
    for (var request in leaveRequests) {
      typeCounts[request.leaveType] = (typeCounts[request.leaveType] ?? 0) + 1;
    }

    // Monthly trends (last 12 months)
    final now = DateTime.now();
    final monthlyData = <String, int>{};

    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = 0;
    }

    for (var request in leaveRequests) {
      final monthKey =
          '${request.startDate.year}-${request.startDate.month.toString().padLeft(2, '0')}';
      if (monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = monthlyData[monthKey]! + 1;
      }
    }

    // Average leave duration
    final durations = leaveRequests
        .map((r) => r.endDate.difference(r.startDate).inDays + 1)
        .toList();
    final averageDuration = durations.isEmpty
        ? 0.0
        : durations.reduce((a, b) => a + b) / durations.length;

    return {
      'totalRequests': leaveRequests.length,
      'statusDistribution': statusCounts,
      'typeDistribution': typeCounts,
      'monthlyTrends': monthlyData,
      'averageDuration': averageDuration,
    };
  }

  // Attendance Analytics
  Future<Map<String, dynamic>> getAttendanceAnalytics() async {
    // For demo purposes, use empty list
    final attendanceRecords = <dynamic>[];
    final employees = await _employeeService.getAllEmployees();

    if (attendanceRecords.isEmpty) {
      return {
        'averageAttendanceRate': 0.0,
        'departmentAttendance': <String, double>{},
        'monthlyTrends': <String, double>{},
        'totalRecords': 0,
      };
    }

    // Overall attendance rate
    final presentRecords = attendanceRecords
        .where((r) => r.status == 'Present')
        .length;
    final overallRate = (presentRecords / attendanceRecords.length) * 100;

    // Department-wise attendance
    final departmentAttendance = <String, List<double>>{};

    for (var record in attendanceRecords) {
      final employee = employees.firstWhere(
        (e) => e.id == record.employeeId,
        orElse: () => Employee(
          id: '',
          name: '',
          email: '',
          department: 'Unknown',
          position: '',
          phone: '',
          joinDate: DateTime.now(),
          salary: 0,
        ),
      );

      if (!departmentAttendance.containsKey(employee.department)) {
        departmentAttendance[employee.department] = [];
      }

      departmentAttendance[employee.department]!.add(
        record.status == 'Present' ? 1.0 : 0.0,
      );
    }

    final departmentRates = <String, double>{};
    departmentAttendance.forEach((dept, rates) {
      departmentRates[dept] =
          (rates.reduce((a, b) => a + b) / rates.length) * 100;
    });

    // Monthly trends
    final now = DateTime.now();
    final monthlyData = <String, List<double>>{};

    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = [];
    }

    for (var record in attendanceRecords) {
      final monthKey =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      if (monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey]!.add(record.status == 'Present' ? 1.0 : 0.0);
      }
    }

    final monthlyRates = <String, double>{};
    monthlyData.forEach((month, rates) {
      monthlyRates[month] = rates.isEmpty
          ? 0.0
          : (rates.reduce((a, b) => a + b) / rates.length) * 100;
    });

    return {
      'averageAttendanceRate': overallRate,
      'departmentAttendance': departmentRates,
      'monthlyTrends': monthlyRates,
      'totalRecords': attendanceRecords.length,
    };
  }

  // Department Analytics
  Future<Map<String, dynamic>> getDepartmentAnalytics() async {
    final departments = await _departmentService.getAllDepartments();
    final employees = await _employeeService.getAllEmployees();

    // Size distribution
    final sizeRanges = <String, int>{
      'Small (1-5)': 0,
      'Medium (6-15)': 0,
      'Large (16+)': 0,
    };

    for (var dept in departments) {
      if (dept.employeeCount <= 5) {
        sizeRanges['Small (1-5)'] = sizeRanges['Small (1-5)']! + 1;
      } else if (dept.employeeCount <= 15) {
        sizeRanges['Medium (6-15)'] = sizeRanges['Medium (6-15)']! + 1;
      } else {
        sizeRanges['Large (16+)'] = sizeRanges['Large (16+)']! + 1;
      }
    }

    // Average salary by department
    final departmentSalaries = <String, List<double>>{};
    for (var employee in employees) {
      if (!departmentSalaries.containsKey(employee.department)) {
        departmentSalaries[employee.department] = [];
      }
      departmentSalaries[employee.department]!.add(employee.salary);
    }

    final avgSalaryByDept = <String, double>{};
    departmentSalaries.forEach((dept, salaries) {
      avgSalaryByDept[dept] =
          salaries.reduce((a, b) => a + b) / salaries.length;
    });

    return {
      'totalDepartments': departments.length,
      'sizeDistribution': sizeRanges,
      'averageSalaryByDepartment': avgSalaryByDept,
      'departmentDetails': departments
          .map(
            (d) => {
              'name': d.name,
              'employeeCount': d.employeeCount,
              'manager': d.managerName,
            },
          )
          .toList(),
    };
  }

  // Dashboard Summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final employees = await _employeeService.getAllEmployees();
    final departments = await _departmentService.getAllDepartments();
    final leaveRequests = await _leaveService.getAllLeaveRequests();
    // For demo purposes, use empty list
    final attendanceRecords = <dynamic>[];

    final pendingLeaves = leaveRequests
        .where((r) => r.status == 'Pending')
        .length;
    final presentToday = attendanceRecords
        .where(
          (r) =>
              r.date.day == DateTime.now().day &&
              r.date.month == DateTime.now().month &&
              r.date.year == DateTime.now().year &&
              r.status == 'Present',
        )
        .length;

    return {
      'totalEmployees': employees.length,
      'totalDepartments': departments.length,
      'pendingLeaves': pendingLeaves,
      'presentToday': presentToday,
      'activeEmployees': employees.where((e) => e.status == 'Active').length,
    };
  }

  // Generate chart data for different chart types
  Future<List<Map<String, dynamic>>> getChartData(String chartType) async {
    switch (chartType) {
      case 'departmentEmployees':
        final analytics = await getEmployeeAnalytics();
        final distribution =
            analytics['departmentDistribution'] as Map<String, int>;
        return distribution.entries
            .map((e) => {'name': e.key, 'value': e.value})
            .toList();

      case 'leaveStatus':
        final analytics = await getLeaveAnalytics();
        final distribution =
            analytics['statusDistribution'] as Map<String, int>;
        return distribution.entries
            .map((e) => {'name': e.key, 'value': e.value})
            .toList();

      case 'attendanceTrends':
        final analytics = await getAttendanceAnalytics();
        final trends = analytics['monthlyTrends'] as Map<String, double>;
        return trends.entries
            .map((e) => {'month': e.key, 'rate': e.value})
            .toList();

      default:
        return [];
    }
  }
}
