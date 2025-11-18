import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../models/employee.dart';
import '../providers/theme_provider.dart';
import '../widgets/change_password_sheet.dart';
import '../services/leave_service.dart';
import '../services/attendance_service.dart';
import '../services/task_service.dart';
import '../services/api_employee_service.dart';
import 'apply_leave_screen.dart';
import 'payslips_screen.dart';
import 'my_attendance_screen.dart';
import 'my_tasks_screen.dart';
import 'team_directory_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final LeaveService _leaveService = LeaveService();
  final AttendanceService _attendanceService = AttendanceService();
  final TaskService _taskService = TaskService();
  final ApiEmployeeService _employeeService = ApiEmployeeService();
  final TextEditingController _statsSearchController = TextEditingController();
  String _statsSearchQuery = '';

  bool _isStatsLoading = true;
  double? _remainingLeaveDays;
  double? _attendanceRate;
  int? _openTasks;
  int? _completedTasks;
  Employee? _currentEmployee;
  bool _isEmployeeLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _statsSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final tabTitles = ['Home', 'Statistics', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(tabTitles[_currentIndex]),
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
        onTap: (value) {
          setState(() => _currentIndex = value);
          if (value == 1) {
            _loadEmployeeStats();
          } else if (value == 2) {
            _loadEmployeeProfile();
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
    final actions = _quickActions(context);
    final filtered = actions
        .where((action) => action.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) => _QuickActionCard(action: filtered[index]),
          ),
          if (filtered.isEmpty)
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
    );
  }

  Widget _buildStatisticsTab(BuildContext context) {
    final metrics = [
      _EmployeeMetric(
        title: 'Leave Balance',
        value: _formatDays(_remainingLeaveDays),
        icon: Icons.calendar_today,
        color: Colors.blue,
      ),
      _EmployeeMetric(
        title: 'Attendance Rate',
        value: _formatPercentage(_attendanceRate),
        icon: Icons.check_circle,
        color: Colors.green,
      ),
      _EmployeeMetric(
        title: 'Open Tasks',
        value: _formatCount(_openTasks),
        icon: Icons.task_alt,
        color: Colors.orange,
      ),
      _EmployeeMetric(
        title: 'Completed Tasks',
        value: _formatCount(_completedTasks),
        icon: Icons.checklist_rounded,
        color: Colors.purple,
      ),
    ];

    final filteredMetrics = metrics
        .where((metric) => metric.title.toLowerCase().contains(_statsSearchQuery.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
          if (_isStatsLoading)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 64), child: CircularProgressIndicator()))
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
      if (_currentEmployee != null)
        _ProfileInfoRow(
          icon: Icons.work,
          label: 'Designation',
          value: _currentEmployee!.position,
        ),
      if (_currentEmployee != null)
        _ProfileInfoRow(
          icon: Icons.business,
          label: 'Department',
          value: _currentEmployee!.department,
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
          if (_isEmployeeLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
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
            colorScheme.tertiary.withOpacity(0.08),
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
                      name.isNotEmpty ? name : 'Employee',
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
              if (_currentEmployee != null)
                _buildProfileBadge(
                  context,
                  icon: Icons.work,
                  label: _currentEmployee!.position,
                  color: colorScheme.tertiary,
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
              subtitle: const Text('Reduce eye strain with a darker palette'),
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

  List<_EmployeeQuickAction> _quickActions(BuildContext context) {
    return [
      _EmployeeQuickAction(
        title: 'Apply for Leave',
        icon: Icons.event_available,
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ApplyLeaveScreen()),
          );
        },
      ),
      _EmployeeQuickAction(
        title: 'View Payslips',
        icon: Icons.receipt_long,
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PayslipsScreen()),
          );
        },
      ),
      _EmployeeQuickAction(
        title: 'My Attendance',
        icon: Icons.access_time,
        color: Colors.teal,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyAttendanceScreen()),
          );
        },
      ),
      _EmployeeQuickAction(
        title: 'My Tasks',
        icon: Icons.assignment,
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyTasksScreen()),
          );
        },
      ),
      _EmployeeQuickAction(
        title: 'Team Directory',
        icon: Icons.people_outline,
        color: Colors.indigo,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TeamDirectoryScreen()),
          );
        },
      ),
    ];
  }

  Future<void> _loadEmployeeStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() => _isStatsLoading = true);

    try {
      final employeeId = user.id;
      final totalLeaveAllowance = 24.0;

      final leaveRequests = await _leaveService.getLeaveRequestsByEmployee(employeeId);
      double usedLeaveDays = 0;
      for (final request in leaveRequests) {
        if (request.status == 'Approved') {
          if (request.halfDay) {
            usedLeaveDays += 0.5;
          } else {
            final diff = request.endDate.difference(request.startDate).inDays + 1;
            if (diff > 0) {
              usedLeaveDays += diff;
            }
          }
        }
      }

      final remainingLeave = (totalLeaveAllowance - usedLeaveDays).clamp(0, totalLeaveAllowance).toDouble();

      final attendanceStats = await _attendanceService.getAttendanceStats(employeeId);
      final attendancePercentage = double.tryParse(
            attendanceStats['attendancePercentage']?.toString() ?? '0',
          ) ??
          0.0;

      final taskStats = await _taskService.getTaskStats(employeeId);
      final openTasks = (taskStats['todoTasks'] as int? ?? 0) + (taskStats['inProgressTasks'] as int? ?? 0);
      final completedTasks = taskStats['completedTasks'] as int? ?? 0;

      if (!mounted) return;
      setState(() {
        _remainingLeaveDays = remainingLeave;
        _attendanceRate = attendancePercentage;
        _openTasks = openTasks;
        _completedTasks = completedTasks;
        _isStatsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _remainingLeaveDays = null;
        _attendanceRate = null;
        _openTasks = null;
        _completedTasks = null;
        _isStatsLoading = false;
      });
    }
  }

  String _formatDays(double? value) {
    if (value == null) return '--';
    final rounded = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$rounded days';
  }

  String _formatPercentage(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(1)}%';
  }

  String _formatCount(int? value) {
    if (value == null) return '--';
    return value.toString();
  }

  Future<void> _loadEmployeeProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null || user.role != UserRole.employee) return;

    setState(() => _isEmployeeLoading = true);

    try {
      final employee = await _employeeService.getCurrentEmployeeProfile();
      if (!mounted) return;
      setState(() {
        _currentEmployee = employee;
        _isEmployeeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentEmployee = null;
        _isEmployeeLoading = false;
      });
      // Silently fail - employee might not have a profile yet
    }
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

class _EmployeeQuickAction {
  const _EmployeeQuickAction({
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _EmployeeQuickAction action;

  @override
  Widget build(BuildContext context) {
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeMetric {
  const _EmployeeMetric({
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
