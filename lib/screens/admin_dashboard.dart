import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'employee_management_screen.dart';
import 'leave_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
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
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Employees',
                    '45',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Departments',
                    '8',
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
                    '12',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Active Projects',
                    '6',
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              'Manage Employees',
              Icons.person_add,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              'Approve Leave Requests',
              Icons.check_circle_outline,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaveManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              'View Reports',
              Icons.analytics,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View Reports - Coming Soon')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              'Manage Departments',
              Icons.corporate_fare,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manage Departments - Coming Soon')),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
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

