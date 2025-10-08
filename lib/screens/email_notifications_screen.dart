import 'package:flutter/material.dart';
import '../services/email_service.dart';
import '../services/employee_service.dart';
import '../services/leave_service.dart';
import '../services/task_service.dart';
import '../models/employee.dart';
import '../models/leave_request.dart';
import '../models/task.dart';

class EmailNotificationsScreen extends StatefulWidget {
  const EmailNotificationsScreen({super.key});

  @override
  State<EmailNotificationsScreen> createState() =>
      _EmailNotificationsScreenState();
}

class _EmailNotificationsScreenState extends State<EmailNotificationsScreen> {
  final EmailService _emailService = EmailService();
  final EmployeeService _employeeService = EmployeeService();
  final LeaveService _leaveService = LeaveService();
  final TaskService _taskService = TaskService();

  bool _isSending = false;
  bool _emailConfigured = false;

  @override
  void initState() {
    super.initState();
    _testEmailConfiguration();
  }

  Future<void> _testEmailConfiguration() async {
    final isConfigured = await _emailService.testEmailConfiguration();
    setState(() => _emailConfigured = isConfigured);
  }

  Future<void> _sendTestLeaveNotification() async {
    setState(() => _isSending = true);

    try {
      final employees = await _employeeService.getAllEmployees();
      if (employees.length < 2) {
        throw Exception('Need at least 2 employees for demo');
      }

      final employee = employees.first;
      final manager = employees[1];

      // Create a sample leave request
      final leaveRequest = LeaveRequest(
        id: 'demo-leave-001',
        employeeId: employee.id,
        employeeName: employee.name,
        leaveType: 'Annual Leave',
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 9)),
        reason: 'Family vacation - Demo notification',
        status: 'Pending',
        requestDate: DateTime.now(),
      );

      final success = await _emailService.sendLeaveRequestNotification(
        leaveRequest: leaveRequest,
        employee: employee,
        manager: manager,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Leave request notification sent successfully!'
                  : 'Failed to send notification. Check email configuration.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendTestTaskNotification() async {
    setState(() => _isSending = true);

    try {
      final employees = await _employeeService.getAllEmployees();
      if (employees.length < 2) {
        throw Exception('Need at least 2 employees for demo');
      }

      final assignee = employees.first;
      final assigner = employees[1];

      // Create a sample task
      final task = Task(
        id: 'demo-task-001',
        title: 'Demo Task Assignment',
        description: 'This is a demonstration task assignment notification',
        assignedTo: assignee.id,
        assignedBy: assigner.id,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        priority: 'High',
        status: 'Pending',
        createdDate: DateTime.now(),
      );

      final success = await _emailService.sendTaskAssignmentNotification(
        task: task,
        assignee: assignee,
        assigner: assigner,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Task assignment notification sent successfully!'
                  : 'Failed to send notification. Check email configuration.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendTestWelcomeEmail() async {
    setState(() => _isSending = true);

    try {
      final employees = await _employeeService.getAllEmployees();
      if (employees.isEmpty) {
        throw Exception('No employees found for demo');
      }

      final employee = employees.first;

      final success = await _emailService.sendWelcomeEmail(
        employee: employee,
        temporaryPassword: 'TempPass123!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Welcome email sent successfully!'
                  : 'Failed to send email. Check email configuration.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendTestBirthdayReminder() async {
    setState(() => _isSending = true);

    try {
      final employees = await _employeeService.getAllEmployees();
      if (employees.isEmpty) {
        throw Exception('No employees found for demo');
      }

      final birthdayEmployee = employees.first;
      final recipients = employees
          .take(3)
          .toList(); // Send to first 3 employees

      final success = await _emailService.sendBirthdayReminder(
        employee: birthdayEmployee,
        recipients: recipients,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Birthday reminder sent successfully!'
                  : 'Failed to send reminder. Check email configuration.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.email,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Email Notifications',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Automated email notifications for HR events',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Configuration Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _emailConfigured ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _emailConfigured ? Icons.check_circle : Icons.error,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _emailConfigured
                                ? 'Email Configured'
                                : 'Email Not Configured',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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

            // Email Notification Options
            Expanded(
              child: ListView(
                children: [
                  _buildEmailOption(
                    title: 'Leave Request Notification',
                    description:
                        'Send notification to manager when employee applies for leave',
                    icon: Icons.event_available,
                    color: Colors.blue,
                    onTap: _sendTestLeaveNotification,
                  ),
                  const SizedBox(height: 16),

                  _buildEmailOption(
                    title: 'Task Assignment Notification',
                    description: 'Notify employee when a new task is assigned',
                    icon: Icons.assignment,
                    color: Colors.orange,
                    onTap: _sendTestTaskNotification,
                  ),
                  const SizedBox(height: 16),

                  _buildEmailOption(
                    title: 'Welcome Email',
                    description:
                        'Send welcome email to new employees with login credentials',
                    icon: Icons.waving_hand,
                    color: Colors.green,
                    onTap: _sendTestWelcomeEmail,
                  ),
                  const SizedBox(height: 16),

                  _buildEmailOption(
                    title: 'Birthday Reminder',
                    description: 'Send birthday reminders to team members',
                    icon: Icons.cake,
                    color: Colors.pink,
                    onTap: _sendTestBirthdayReminder,
                  ),
                  const SizedBox(height: 16),

                  _buildEmailOption(
                    title: 'Payslip Notification',
                    description: 'Notify employees when payslips are available',
                    icon: Icons.receipt,
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payslip notifications - Coming Soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Configuration Note
            if (!_emailConfigured)
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(top: 16.0),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Email Configuration Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'To enable email notifications, configure SMTP settings in EmailService. '
                      'Update the email credentials with your company\'s email server details.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Loading indicator
            if (_isSending)
              Container(
                padding: const EdgeInsets.all(16.0),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Sending email...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isSending ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.send, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
