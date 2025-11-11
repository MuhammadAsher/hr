import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
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
import 'payslip_management_screen.dart';

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
  int _activeEmployees = 0;
  bool _isLoading = true;
  int _currentIndex = 0;
  String _quickSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _statsSearchController = TextEditingController();
  String _statsSearchQuery = '';

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
    _searchController.dispose();
    _statsSearchController.dispose();
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
        _fetchActiveEmployees(),
      ]);

      setState(() {
        _totalEmployees = results[0] as int;
        _totalDepartments = results[1] as int;
        _pendingLeaves = results[2] as int;
        _activeEmployees = results[3] as int;
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

  Future<int> _fetchActiveEmployees() async {
    try {
      final employees = await _employeeService.getAllEmployees(status: 'active', limit: 1000);
      return employees.length;
    } catch (e) {
      print('Error fetching active employees: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final titles = ['Home', 'Statistics', 'Profile'];
    final actions = <Widget>[
      if (_currentIndex == 1)
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardData,
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: actions,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(context, user),
          _buildStatisticsTab(context),
          _buildProfileTab(context, authProvider, user),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            _loadDashboardData();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Statistics'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, User? user) {
    final actions = _buildQuickActions(context);
    final filteredActions = actions
        .where(
          (action) => action.title.toLowerCase().contains(_quickSearchQuery.toLowerCase()),
        )
        .toList();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _quickSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _quickSearchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _quickSearchQuery = value),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              itemCount: filteredActions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final action = filteredActions[index];
                return _buildQuickActionCard(action);
              },
            ),
            if (filteredActions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('No quick actions found', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(BuildContext context) {
    final metrics = [
      _DashboardMetric(
        title: 'Total Employees',
        value: _isLoading ? '...' : _totalEmployees.toString(),
        icon: Icons.people,
        color: Colors.blue,
      ),
      _DashboardMetric(
        title: 'Departments',
        value: _isLoading ? '...' : _totalDepartments.toString(),
        icon: Icons.business,
        color: Colors.green,
      ),
      _DashboardMetric(
        title: 'Pending Leaves',
        value: _isLoading ? '...' : _pendingLeaves.toString(),
        icon: Icons.pending_actions,
        color: Colors.orange,
      ),
      _DashboardMetric(
        title: 'Active Employees',
        value: _isLoading ? '...' : _activeEmployees.toString(),
        icon: Icons.verified_rounded,
        color: Colors.purple,
      ),
    ];

    final filteredMetrics = metrics
        .where((metric) => metric.title.toLowerCase().contains(_statsSearchQuery.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _statsSearchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _statsSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _statsSearchQuery = '';
                          _statsSearchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _statsSearchQuery = value),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredMetrics.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('No statistics found', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 420 ? 3 : 2;
                final width = (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
                final height = width * 0.9 + 48;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: width / height,
                  ),
                  itemCount: filteredMetrics.length,
                  itemBuilder: (context, index) {
                    final metric = filteredMetrics[index];
                    return _buildStatCard(context, metric.title, metric.value, metric.icon, metric.color);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, AuthProvider authProvider, User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'A',
                          style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Admin',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(user?.email ?? '', style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text((user?.role.name ?? 'admin').toUpperCase()),
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your account security'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Change password coming soon')),);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Account Settings'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account settings coming soon')),);
                    },
                  ),
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authProvider.logout();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_QuickAction> _buildQuickActions(BuildContext context) {
    return [
      _QuickAction(
        title: 'Manage Employees',
        icon: Icons.person_add,
        color: Colors.blue,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmployeeManagementScreen()),
          );
          _loadDashboardData();
        },
      ),
      _QuickAction(
        title: 'Approve Leave Requests',
        icon: Icons.check_circle_outline,
        color: Colors.orange,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaveManagementScreen()),
          );
          _loadDashboardData();
        },
      ),
      _QuickAction(
        title: 'View Reports',
        icon: Icons.analytics,
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportsAnalyticsScreen()),
          );
        },
      ),
      _QuickAction(
        title: 'Manage Departments',
        icon: Icons.corporate_fare,
        color: Colors.green,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DepartmentManagementScreen()),
          );
          _loadDashboardData();
        },
      ),
      _QuickAction(
        title: 'Manage Payslips',
        icon: Icons.receipt_long,
        color: Colors.indigo,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PayslipManagementScreen()),
          );
          _loadDashboardData();
        },
      ),
      _QuickAction(
        title: 'Generate PDFs',
        icon: Icons.picture_as_pdf,
        color: Colors.redAccent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PdfGenerationScreen()),
          );
        },
      ),
      _QuickAction(
        title: 'Email Notifications',
        icon: Icons.email_outlined,
        color: Colors.teal,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmailNotificationsScreen()),
          );
        },
      ),
      _QuickAction(
        title: 'Advanced Reports',
        icon: Icons.dashboard_customize,
        color: Colors.deepOrange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdvancedReportingScreen()),
          );
        },
      ),
    ];
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: action.onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withOpacity(0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: action.color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: action.color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
              ),
            ],
          ),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2), width: 1.2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}
