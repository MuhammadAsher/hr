import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../services/employee_service.dart';
import '../services/leave_service.dart';
import '../services/attendance_service.dart';
import '../services/department_service.dart';
import '../services/pdf_service.dart';
import '../models/employee.dart';
import '../models/leave_request.dart';
import '../models/attendance.dart';
import '../models/department.dart';

class AdvancedReportingScreen extends StatefulWidget {
  const AdvancedReportingScreen({super.key});

  @override
  State<AdvancedReportingScreen> createState() =>
      _AdvancedReportingScreenState();
}

class _AdvancedReportingScreenState extends State<AdvancedReportingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final EmployeeService _employeeService = EmployeeService();
  final LeaveService _leaveService = LeaveService();
  final AttendanceService _attendanceService = AttendanceService();
  final DepartmentService _departmentService = DepartmentService();
  final PdfService _pdfService = PdfService();

  bool _isGenerating = false;

  // Filters
  String? _selectedDepartment;
  String? _selectedStatus;
  DateTimeRange? _dateRange;
  List<String> _departments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final departments = await _departmentService.getAllDepartments();
    setState(() {
      _departments = departments.map((d) => d.name).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDepartment = null;
      _selectedStatus = null;
      _dateRange = null;
    });
  }

  Future<void> _exportEmployeeReport() async {
    setState(() => _isGenerating = true);

    try {
      final employees = await _employeeService.getAllEmployees();
      final filteredEmployees = _filterEmployees(employees);

      await _showExportDialog(
        'Employee Report',
        () async {
          // CSV Export
          final csvData = [
            [
              'Name',
              'Email',
              'Department',
              'Position',
              'Status',
              'Join Date',
              'Salary',
            ],
            ...filteredEmployees.map(
              (e) => [
                e.name,
                e.email,
                e.department,
                e.position,
                e.status,
                '${e.joinDate.day}/${e.joinDate.month}/${e.joinDate.year}',
                e.salary.toString(),
              ],
            ),
          ];
          return csvData;
        },
        () async {
          // PDF Export
          return await _pdfService.generateEmployeeReport(filteredEmployees);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportLeaveReport() async {
    setState(() => _isGenerating = true);

    try {
      final leaveRequests = await _leaveService.getAllLeaveRequests();
      final filteredLeaves = _filterLeaveRequests(leaveRequests);

      await _showExportDialog('Leave Report', () async {
        // CSV Export
        final csvData = [
          [
            'Employee',
            'Type',
            'Start Date',
            'End Date',
            'Duration',
            'Status',
            'Applied Date',
            'Reason',
          ],
          ...filteredLeaves.map(
            (l) => [
              l.employeeName,
              l.leaveType,
              '${l.startDate.day}/${l.startDate.month}/${l.startDate.year}',
              '${l.endDate.day}/${l.endDate.month}/${l.endDate.year}',
              '${l.endDate.difference(l.startDate).inDays + 1} days',
              l.status,
              '${l.requestDate.day}/${l.requestDate.month}/${l.requestDate.year}',
              l.reason,
            ],
          ),
        ];
        return csvData;
      }, null); // PDF not implemented for leave report in this demo
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportAttendanceReport() async {
    setState(() => _isGenerating = true);

    try {
      // For demo purposes, create dummy attendance data
      final csvData = [
        [
          'Employee ID',
          'Employee Name',
          'Date',
          'Check In',
          'Check Out',
          'Hours Worked',
          'Status',
        ],
        [
          'EMP001',
          'John Doe',
          '2024-01-15',
          '09:00',
          '17:30',
          '8.5',
          'Present',
        ],
        [
          'EMP002',
          'Jane Smith',
          '2024-01-15',
          '09:15',
          '17:45',
          '8.5',
          'Present',
        ],
        ['EMP003', 'Bob Johnson', '2024-01-15', '', '', '0.0', 'Absent'],
        [
          'EMP001',
          'John Doe',
          '2024-01-16',
          '09:00',
          '13:00',
          '4.0',
          'Half Day',
        ],
        [
          'EMP002',
          'Jane Smith',
          '2024-01-16',
          '09:10',
          '17:40',
          '8.5',
          'Present',
        ],
      ];

      await _showExportDialog('Attendance Report', () async {
        return csvData;
      }, null); // PDF not implemented for attendance report in this demo
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportDepartmentReport() async {
    setState(() => _isGenerating = true);

    try {
      final departments = await _departmentService.getAllDepartments();
      final employees = await _employeeService.getAllEmployees();

      await _showExportDialog(
        'Department Report',
        () async {
          // CSV Export
          final csvData = [
            [
              'Department',
              'Description',
              'Manager',
              'Employee Count',
              'Average Salary',
            ],
            ...departments.map((d) {
              final deptEmployees = employees
                  .where((e) => e.department == d.name)
                  .toList();
              final avgSalary = deptEmployees.isNotEmpty
                  ? deptEmployees.map((e) => e.salary).reduce((a, b) => a + b) /
                        deptEmployees.length
                  : 0.0;
              return [
                d.name,
                d.description,
                d.managerName,
                d.employeeCount.toString(),
                avgSalary.toStringAsFixed(2),
              ];
            }),
          ];
          return csvData;
        },
        () async {
          // PDF Export
          return await _pdfService.generateDepartmentReport(
            departments,
            employees,
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _showExportDialog(
    String reportName,
    Future<List<List<dynamic>>> Function() csvGenerator,
    Future<List<int>> Function()? pdfGenerator,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export $reportName'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _exportToCsv(reportName, await csvGenerator());
            },
            child: const Text('CSV'),
          ),
          if (pdfGenerator != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final pdfBytes = await pdfGenerator();
                await _exportToPdf(reportName, Uint8List.fromList(pdfBytes));
              },
              child: const Text('PDF'),
            ),
        ],
      ),
    );
  }

  Future<void> _exportToCsv(String reportName, List<List<dynamic>> data) async {
    try {
      final csv = const ListToCsvConverter().convert(data);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${reportName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV exported to: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting CSV: $e')));
      }
    }
  }

  Future<void> _exportToPdf(String reportName, Uint8List pdfBytes) async {
    try {
      final fileName =
          '${reportName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final path = await _pdfService.savePdfToDevice(pdfBytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF exported to: $path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
      }
    }
  }

  List<Employee> _filterEmployees(List<Employee> employees) {
    return employees.where((employee) {
      if (_selectedDepartment != null &&
          employee.department != _selectedDepartment) {
        return false;
      }
      if (_selectedStatus != null && employee.status != _selectedStatus) {
        return false;
      }
      if (_dateRange != null) {
        if (employee.joinDate.isBefore(_dateRange!.start) ||
            employee.joinDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<LeaveRequest> _filterLeaveRequests(List<LeaveRequest> requests) {
    return requests.where((request) {
      if (_selectedStatus != null && request.status != _selectedStatus) {
        return false;
      }
      if (_dateRange != null) {
        if (request.requestDate.isBefore(_dateRange!.start) ||
            request.requestDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<Attendance> _filterAttendanceRecords(List<Attendance> records) {
    return records.where((record) {
      if (_dateRange != null) {
        if (record.date.isBefore(_dateRange!.start) ||
            record.date.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Reporting'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Employees', icon: Icon(Icons.people)),
            Tab(text: 'Leave', icon: Icon(Icons.event_available)),
            Tab(text: 'Attendance', icon: Icon(Icons.access_time)),
            Tab(text: 'Departments', icon: Icon(Icons.business)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    // Department Filter
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Departments'),
                          ),
                          ..._departments.map(
                            (dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedDepartment = value),
                      ),
                    ),

                    // Status Filter
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem(
                            value: 'Active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'Inactive',
                            child: Text('Inactive'),
                          ),
                          DropdownMenuItem(
                            value: 'Pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'Approved',
                            child: Text('Approved'),
                          ),
                          DropdownMenuItem(
                            value: 'Rejected',
                            child: Text('Rejected'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedStatus = value),
                      ),
                    ),

                    // Date Range Filter
                    SizedBox(
                      width: 200,
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _dateRange == null
                              ? 'Select Date Range'
                              : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                        ),
                      ),
                    ),

                    // Clear Filters
                    OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportTab(
                  'Employee Reports',
                  'Generate comprehensive employee reports with filters',
                  Icons.people,
                  Colors.blue,
                  _exportEmployeeReport,
                ),
                _buildReportTab(
                  'Leave Reports',
                  'Export leave request data and analytics',
                  Icons.event_available,
                  Colors.green,
                  _exportLeaveReport,
                ),
                _buildReportTab(
                  'Attendance Reports',
                  'Generate attendance tracking reports',
                  Icons.access_time,
                  Colors.orange,
                  _exportAttendanceReport,
                ),
                _buildReportTab(
                  'Department Reports',
                  'Export department structure and analytics',
                  Icons.business,
                  Colors.purple,
                  _exportDepartmentReport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTab(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onExport,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 64, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : onExport,
            icon: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_isGenerating ? 'Generating...' : 'Export Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          if (_dateRange != null ||
              _selectedDepartment != null ||
              _selectedStatus != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Filters:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_selectedDepartment != null)
                    Text('• Department: $_selectedDepartment'),
                  if (_selectedStatus != null)
                    Text('• Status: $_selectedStatus'),
                  if (_dateRange != null)
                    Text(
                      '• Date Range: ${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} - ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}',
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
