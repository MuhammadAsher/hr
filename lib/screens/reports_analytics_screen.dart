import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/analytics_service.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, dynamic> _employeeAnalytics = {};
  Map<String, dynamic> _leaveAnalytics = {};
  Map<String, dynamic> _attendanceAnalytics = {};
  Map<String, dynamic> _departmentAnalytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _analyticsService.getEmployeeAnalytics(),
        _analyticsService.getLeaveAnalytics(),
        _analyticsService.getAttendanceAnalytics(),
        _analyticsService.getDepartmentAnalytics(),
      ]);

      setState(() {
        _employeeAnalytics = results[0];
        _leaveAnalytics = results[1];
        _attendanceAnalytics = results[2];
        _departmentAnalytics = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEmployeeAnalytics(),
                _buildLeaveAnalytics(),
                _buildAttendanceAnalytics(),
                _buildDepartmentAnalytics(),
              ],
            ),
    );
  }

  Widget _buildEmployeeAnalytics() {
    if (_employeeAnalytics.isEmpty) {
      return const Center(child: Text('No employee data available'));
    }

    final departmentData =
        _employeeAnalytics['departmentDistribution'] as Map<String, int>;
    final statusData =
        _employeeAnalytics['statusDistribution'] as Map<String, int>;
    final salaryData =
        _employeeAnalytics['salaryAnalytics'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Employees',
                  '${_employeeAnalytics['totalEmployees']}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Departments',
                  '${_employeeAnalytics['totalDepartments']}',
                  Icons.business,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Avg Salary',
                  '\$${salaryData['average'].toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Avg Tenure',
                  '${_employeeAnalytics['averageTenure'].toStringAsFixed(1)} years',
                  Icons.schedule,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Department Distribution Chart
          _buildChartCard(
            'Employees by Department',
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                series: <PieSeries<MapEntry<String, int>, String>>[
                  PieSeries<MapEntry<String, int>, String>(
                    dataSource: departmentData.entries.toList(),
                    xValueMapper: (MapEntry<String, int> data, _) => data.key,
                    yValueMapper: (MapEntry<String, int> data, _) => data.value,
                    dataLabelMapper: (MapEntry<String, int> data, _) =>
                        '${data.value}',
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Distribution Chart
          _buildChartCard(
            'Employee Status Distribution',
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                primaryYAxis: const NumericAxis(),
                series: <ColumnSeries<MapEntry<String, int>, String>>[
                  ColumnSeries<MapEntry<String, int>, String>(
                    dataSource: statusData.entries.toList(),
                    xValueMapper: (MapEntry<String, int> data, _) => data.key,
                    yValueMapper: (MapEntry<String, int> data, _) => data.value,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveAnalytics() {
    if (_leaveAnalytics.isEmpty) {
      return const Center(child: Text('No leave data available'));
    }

    final statusData =
        _leaveAnalytics['statusDistribution'] as Map<String, int>;
    final typeData = _leaveAnalytics['typeDistribution'] as Map<String, int>;
    final monthlyData = _leaveAnalytics['monthlyTrends'] as Map<String, int>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Requests',
                  '${_leaveAnalytics['totalRequests']}',
                  Icons.event_available,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Avg Duration',
                  '${_leaveAnalytics['averageDuration'].toStringAsFixed(1)} days',
                  Icons.schedule,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Leave Status Chart
          _buildChartCard(
            'Leave Requests by Status',
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                series: <DoughnutSeries<MapEntry<String, int>, String>>[
                  DoughnutSeries<MapEntry<String, int>, String>(
                    dataSource: statusData.entries.toList(),
                    xValueMapper: (MapEntry<String, int> data, _) => data.key,
                    yValueMapper: (MapEntry<String, int> data, _) => data.value,
                    dataLabelMapper: (MapEntry<String, int> data, _) =>
                        '${data.value}',
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Leave Type Chart
          _buildChartCard(
            'Leave Requests by Type',
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                primaryYAxis: const NumericAxis(),
                series: <ColumnSeries<MapEntry<String, int>, String>>[
                  ColumnSeries<MapEntry<String, int>, String>(
                    dataSource: typeData.entries.toList(),
                    xValueMapper: (MapEntry<String, int> data, _) => data.key,
                    yValueMapper: (MapEntry<String, int> data, _) => data.value,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Trends
          _buildChartCard(
            'Monthly Leave Trends',
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                primaryYAxis: const NumericAxis(),
                series: <LineSeries<MapEntry<String, int>, String>>[
                  LineSeries<MapEntry<String, int>, String>(
                    dataSource: monthlyData.entries.toList(),
                    xValueMapper: (MapEntry<String, int> data, _) =>
                        data.key.substring(5),
                    yValueMapper: (MapEntry<String, int> data, _) => data.value,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: Colors.purple,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceAnalytics() {
    if (_attendanceAnalytics.isEmpty) {
      return const Center(child: Text('No attendance data available'));
    }

    final departmentData =
        _attendanceAnalytics['departmentAttendance'] as Map<String, double>;
    final monthlyData =
        _attendanceAnalytics['monthlyTrends'] as Map<String, double>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Overall Rate',
                  '${_attendanceAnalytics['averageAttendanceRate'].toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Records',
                  '${_attendanceAnalytics['totalRecords']}',
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Department Attendance Chart
          if (departmentData.isNotEmpty)
            _buildChartCard(
              'Attendance by Department',
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(),
                  primaryYAxis: const NumericAxis(minimum: 0, maximum: 100),
                  series: <ColumnSeries<MapEntry<String, double>, String>>[
                    ColumnSeries<MapEntry<String, double>, String>(
                      dataSource: departmentData.entries.toList(),
                      xValueMapper: (MapEntry<String, double> data, _) =>
                          data.key,
                      yValueMapper: (MapEntry<String, double> data, _) =>
                          data.value,
                      dataLabelMapper: (MapEntry<String, double> data, _) =>
                          '${data.value.toStringAsFixed(1)}%',
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                      ),
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Monthly Trends
          if (monthlyData.isNotEmpty)
            _buildChartCard(
              'Monthly Attendance Trends',
              SizedBox(
                height: 250,
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(),
                  primaryYAxis: const NumericAxis(minimum: 0, maximum: 100),
                  series: <LineSeries<MapEntry<String, double>, String>>[
                    LineSeries<MapEntry<String, double>, String>(
                      dataSource: monthlyData.entries.toList(),
                      xValueMapper: (MapEntry<String, double> data, _) =>
                          data.key.substring(5),
                      yValueMapper: (MapEntry<String, double> data, _) =>
                          data.value,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                      ),
                      color: Colors.blue,
                      markerSettings: const MarkerSettings(isVisible: true),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentAnalytics() {
    if (_departmentAnalytics.isEmpty) {
      return const Center(child: Text('No department data available'));
    }

    final sizeData =
        _departmentAnalytics['sizeDistribution'] as Map<String, int>;
    final salaryData =
        _departmentAnalytics['averageSalaryByDepartment']
            as Map<String, double>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildSummaryCard(
            'Total Departments',
            '${_departmentAnalytics['totalDepartments']}',
            Icons.business,
            Colors.blue,
          ),
          const SizedBox(height: 24),

          // Department Size Distribution
          _buildChartCard(
            'Department Size Distribution',
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                series: <PieSeries<MapEntry<String, int>, String>>[
                  PieSeries<MapEntry<String, int>, String>(
                    dataSource: sizeData.entries.toList(),
                    xValueMapper: (MapEntry<String, int> data, _) => data.key,
                    yValueMapper: (MapEntry<String, int> data, _) => data.value,
                    dataLabelMapper: (MapEntry<String, int> data, _) =>
                        '${data.value}',
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Average Salary by Department
          if (salaryData.isNotEmpty)
            _buildChartCard(
              'Average Salary by Department',
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(),
                  primaryYAxis: const NumericAxis(),
                  series: <ColumnSeries<MapEntry<String, double>, String>>[
                    ColumnSeries<MapEntry<String, double>, String>(
                      dataSource: salaryData.entries.toList(),
                      xValueMapper: (MapEntry<String, double> data, _) =>
                          data.key,
                      yValueMapper: (MapEntry<String, double> data, _) =>
                          data.value,
                      dataLabelMapper: (MapEntry<String, double> data, _) =>
                          '\$${data.value.toStringAsFixed(0)}',
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                      ),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            chart,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
