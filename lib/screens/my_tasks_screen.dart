import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _filter = 'All'; // All, Todo, In Progress, Completed

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tasks = await _taskService.getTasksByEmployee(authProvider.currentUser!.id);
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  List<Task> get _filteredTasks {
    if (_filter == 'All') return _tasks;
    return _tasks.where((task) => task.status == _filter).toList();
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    await _taskService.updateTaskStatus(taskId, newStatus);
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task status updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todoCount = _tasks.where((t) => t.status == 'Todo').length;
    final inProgressCount = _tasks.where((t) => t.status == 'In Progress').length;
    final completedCount = _tasks.where((t) => t.status == 'Completed').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      body: Column(
        children: [
          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Todo', todoCount, Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('In Progress', inProgressCount, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Done', completedCount, Colors.green),
                ),
              ],
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Todo', 'In Progress', 'Completed'].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (selected) {
                        setState(() => _filter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Task List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? const Center(child: Text('No tasks found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = _filteredTasks[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: _getPriorityColor(task.priority),
                                child: Text(
                                  task.priority.substring(0, 1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: task.status == 'Completed'
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: task.isOverdue ? Colors.red : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                                        style: TextStyle(
                                          color: task.isOverdue ? Colors.red : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (task.isOverdue) ...[
                                        const SizedBox(width: 8),
                                        const Text(
                                          'OVERDUE',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(
                                  task.status,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor:
                                    _getStatusColor(task.status).withOpacity(0.2),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Description:',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(task.description),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Assigned by: ${task.assignedBy}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Update Status:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: ['Todo', 'In Progress', 'Completed']
                                            .map((status) {
                                          return ChoiceChip(
                                            label: Text(status),
                                            selected: task.status == status,
                                            onSelected: (selected) {
                                              if (selected) {
                                                _updateTaskStatus(task.id, status);
                                              }
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Todo':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

