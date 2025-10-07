import '../models/task.dart';

class TaskService {
  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Complete Q4 Report',
      description: 'Prepare and submit the quarterly financial report',
      assignedTo: '2',
      assignedBy: 'Admin User',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      priority: 'High',
      status: 'In Progress',
      createdDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Task(
      id: '2',
      title: 'Update Employee Handbook',
      description: 'Review and update company policies in the employee handbook',
      assignedTo: '2',
      assignedBy: 'Admin User',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      priority: 'Medium',
      status: 'Todo',
      createdDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Task(
      id: '3',
      title: 'Organize Team Building Event',
      description: 'Plan and coordinate the upcoming team building activity',
      assignedTo: '2',
      assignedBy: 'Admin User',
      dueDate: DateTime.now().add(const Duration(days: 14)),
      priority: 'Low',
      status: 'Todo',
      createdDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Task(
      id: '4',
      title: 'Review Performance Evaluations',
      description: 'Complete performance reviews for team members',
      assignedTo: '2',
      assignedBy: 'Admin User',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      priority: 'High',
      status: 'In Progress',
      createdDate: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  Future<List<Task>> getAllTasks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_tasks);
  }

  Future<List<Task>> getTasksByEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _tasks.where((task) => task.assignedTo == employeeId).toList();
  }

  Future<List<Task>> getTasksByStatus(String status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _tasks.where((task) => task.status == status).toList();
  }

  Future<bool> createTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tasks.add(task);
    return true;
  }

  Future<bool> updateTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      return true;
    }
    return false;
  }

  Future<bool> updateTaskStatus(String id, String status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: status);
      return true;
    }
    return false;
  }

  Future<bool> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks.removeAt(index);
      return true;
    }
    return false;
  }
}

