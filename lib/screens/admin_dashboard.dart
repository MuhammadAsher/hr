import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_employee_service.dart';
import '../services/department_service.dart';
import '../services/leave_service.dart';
import '../services/error_service.dart';
import '../main.dart';
import 'employee_management_screen.dart';
import 'leave_management_screen.dart';
import 'department_management_screen.dart';
import 'reports_analytics_screen.dart';
import 'pdf_generation_screen.dart';
import 'email_notifications_screen.dart';
import 'advanced_reporting_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with RouteAware, WidgetsBindingObserver {
  final ApiEmployeeService _employeeService = ApiEmployeeService();
  final DepartmentService _departmentService = DepartmentService();
  final LeaveService _leaveService = LeaveService();

  int _totalEmployees = 0;
  int _totalDepartments = 0;
  int _pendingLeaves = 0;
  int _activeProjects = 0; // This might need a task service if implemented
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _loadDashboardData();
    }
  }

  // Called when the current route has been pushed.
  @override
  void didPush() {
    _loadDashboardData();
  }

  // Called when the top route has been popped off, and this route shows up.
  @override
  void didPopNext() {
    // Refresh data when returning to this screen
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _fetchTotalEmployees(),
        _fetchTotalDepartments(),
        _fetchPendingLeaves(),
        _fetchActiveProjects(),
      ]);

      setState(() {
        _totalEmployees = results[0] as int;
        _totalDepartments = results[1] as int;
        _pendingLeaves = results[2] as int;
        _activeProjects = results[3] as int;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorService.showErrorSnackbar(
          message: 'Failed to load dashboard data',
          error: 'Loading Error',
        );
      }
    }
  }

  Future<int> _fetchTotalEmployees() async {
    try {
      // Use the efficient count method - gets all employees (no status filter)
      return await _employeeService.getTotalEmployeeCount();
    } catch (e) {
      print('Error fetching employee count: $e');
      // Fallback to fetching all employees and counting
      try {
        // Fetch all employees with high limit (don't pass status to get all)
        final employees = await _employeeService.getAllEmployees(limit: 1000);
        return employees.length;
      } catch (e2) {
        print('Fallback also failed: $e2');
        return 0;
      }
    }
  }

  Future<int> _fetchTotalDepartments() async {
    try {
      // Fetch departments - API returns paginated response
      // For now, fetch with high limit to get count
      final departments = await _departmentService.getAllDepartments(limit: 1000);
      return departments.length;
    } catch (e) {
      print('Error fetching departments: $e');
      return 0;
    }
  }

  Future<int> _fetchPendingLeaves() async {
    try {
      // Fetch pending leave requests
      final leaveRequests = await _leaveService.getAllLeaveRequests(
        status: 'pending',
        limit: 1000,
      );
      return leaveRequests.length;
    } catch (e) {
      print('Error fetching pending leaves: $e');
      return 0;
    }
  }

  Future<int> _fetchActiveProjects() async {
    // TODO: Implement when task/project service is available
    // For now, return 0
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            user?.name ?? 'Admin',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadDashboardData,
                    tooltip: 'Refresh',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Employees',
                    _isLoading ? '...' : _totalEmployees.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Departments',
                    _isLoading ? '...' : _totalDepartments.toString(),
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
                  child: _buildStatCard(
                    context,
                    'Pending Leaves',
                    _isLoading ? '...' : _pendingLeaves.toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Active Projects',
                    _isLoading ? '...' : _activeProjects.toString(),
                    Icons.work,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              'Manage Employees',
              Icons.person_add,
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeManagementScreen(),
                  ),
                );
                // Refresh dashboard data when returning from employee management
                _loadDashboardData();
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              'Approve Leave Requests',
              Icons.check_circle_outline,
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaveManagementScreen(),
                  ),
                );
                // Refresh dashboard data when returning from leave management
                _loadDashboardData();
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(context, 'View Reports', Icons.analytics, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsAnalyticsScreen(),
                ),
              );
            }),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              'Manage Departments',
              Icons.corporate_fare,
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DepartmentManagementScreen(),
                  ),
                );
                // Refresh dashboard data when returning from department management
                _loadDashboardData();
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              'Generate PDFs',
              Icons.picture_as_pdf,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PdfGenerationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(context, 'Email Notifications', Icons.email, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmailNotificationsScreen(),
                ),
              );
            }),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              'Advanced Reports',
              Icons.analytics_outlined,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdvancedReportingScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
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

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
