import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../providers/theme_provider.dart';
import '../widgets/change_password_sheet.dart';
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
  bool _isLoadingData = false; // Prevent concurrent requests
  DateTime? _lastLoadTime; // Track last load time
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
      // Refresh data when app comes back to foreground (with debounce)
      _loadDashboardData(force: false);
    }
  }

  // Called when the current route has been pushed.
  @override
  void didPush() {
    // Only load if not already loaded recently
    _loadDashboardData(force: false);
  }

  // Called when the top route has been popped off, and this route shows up.
  @override
  void didPopNext() {
    // Refresh data when returning to this screen (with debounce)
    _loadDashboardData(force: false);
  }

  Future<void> _loadDashboardData({bool force = false}) async {
    // Prevent concurrent requests
    if (_isLoadingData && !force) {
      print('⏸️ Dashboard data already loading, skipping...');
      return;
    }

    // Debounce: Don't load if loaded within last 2 seconds (unless forced)
    if (!force && _lastLoadTime != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastLoadTime!);
      if (timeSinceLastLoad.inSeconds < 2) {
        print('⏸️ Dashboard data loaded recently (${timeSinceLastLoad.inSeconds}s ago), skipping...');
        return;
      }
    }

    _isLoadingData = true;
    _lastLoadTime = DateTime.now();
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
        _isLoadingData = false;
      });
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
        _isLoadingData = false;
      });
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
          onPressed: () => _loadDashboardData(force: true),
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
            _loadDashboardData(force: true); // Force load when switching to Statistics tab
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
      onRefresh: () => _loadDashboardData(force: true),
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
    if (user == null) {
      return const Center(child: Text('User information unavailable'));
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final infoRows = <_ProfileInfoRow>[
      _ProfileInfoRow(
        icon: Icons.verified_user,
        label: 'Account Type',
        value: _formatRole(user.role),
      ),
      if ((user.organizationName ?? '').isNotEmpty)
        _ProfileInfoRow(
          icon: Icons.apartment,
          label: 'Organization',
          value: user.organizationName!,
        ),
      _ProfileInfoRow(
        icon: Icons.alternate_email,
        label: 'Email',
        value: user.email,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(context, user),
          const SizedBox(height: 24),
          _buildInfoSection(context, infoRows),
          const SizedBox(height: 24),
          _buildPreferencesSection(context, themeProvider, authProvider),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await authProvider.logout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = user.name; 
    final fallbackInitial = user.email.isNotEmpty ? user.email[0] : '?';
    final initials = name.isNotEmpty ? name[0] : fallbackInitial;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.12),
            colorScheme.secondary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.primary,
                child: Text(
                  initials.toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Administrator',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildProfileBadge(
                context,
                icon: Icons.verified_user,
                label: _formatRole(user.role),
                color: colorScheme.primary,
              ),
              if ((user.organizationName ?? '').isNotEmpty)
                _buildProfileBadge(
                  context,
                  icon: Icons.apartment,
                  label: user.organizationName!,
                  color: colorScheme.secondary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, List<_ProfileInfoRow> rows) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              _buildInfoRow(context, rows[i]),
              if (i != rows.length - 1)
                const Divider(height: 24, thickness: 0.6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, _ProfileInfoRow row) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(row.icon, color: colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                row.value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    ThemeProvider themeProvider,
    AuthProvider authProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(value),
              title: const Text('Dark Mode'),
              subtitle: const Text('Toggle a darker color palette across the app'),
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: colorScheme.primary,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            const Divider(indent: 12, endIndent: 12, thickness: 0.6),
            ListTile(
              leading: Icon(Icons.lock_reset, color: colorScheme.primary),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account security settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _openChangePasswordSheet(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(UserRole role) {
    final formatted = role.name.replaceAll('_', ' ');
    return formatted
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  List<_QuickAction> _buildQuickActions(BuildContext context) {
    return [
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
        title: 'Manage Employees',
        icon: Icons.person_add,
        color: Colors.blue,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmployeeManagementScreen()),
          );
          _loadDashboardData(force: true);
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
          _loadDashboardData(force: true);
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
        title: 'Manage Payslips',
        icon: Icons.receipt_long,
        color: Colors.indigo,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PayslipManagementScreen()),
          );
          _loadDashboardData(force: true);
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

  Future<void> _openChangePasswordSheet(BuildContext context, AuthProvider authProvider) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangePasswordSheet(authProvider: authProvider),
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    }
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

class _ProfileInfoRow {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}
