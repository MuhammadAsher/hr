import '../models/task.dart';
import 'api_client.dart';

class TaskService {
  final ApiClient _apiClient = ApiClient();

  // Get all tasks
  Future<List<Task>> getAllTasks({
    int page = 1,
    int limit = 10,
    String? status,
    String? priority,
    String? assignedTo,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status != 'all') queryParams['status'] = status;
      if (priority != null && priority != 'all')
        queryParams['priority'] = priority;
      if (assignedTo != null && assignedTo != 'all')
        queryParams['assignedTo'] = assignedTo;

      final response = await _apiClient.get('/tasks', queryParams: queryParams);

      if (response.isSuccess) {
        final responseData = response.data['data'];
        final List<dynamic> tasks = responseData['tasks'] ?? [];
        return tasks.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(response.message ?? 'Failed to fetch tasks');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockTasks();
    }
  }

  // Get task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      final response = await _apiClient.get('/tasks/$taskId');

      if (response.isSuccess) {
        return Task.fromJson(response.data['data']);
      } else {
        throw Exception(response.message ?? 'Failed to fetch task');
      }
    } catch (e) {
      // Fallback to mock data
      final mockTasks = _getMockTasks();
      return mockTasks.firstWhere(
        (task) => task.id == taskId,
        orElse: () => mockTasks.first,
      );
    }
  }

  // Create new task
  Future<bool> createTask({
    required String title,
    String? description,
    String? assignedTo,
    String priority = 'medium',
    String status = 'pending',
    DateTime? dueDate,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'priority': priority,
        'status': status,
      };

      if (description != null) body['description'] = description;
      if (assignedTo != null) body['assignedTo'] = assignedTo;
      if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

      final response = await _apiClient.post('/tasks', body: body);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Update task
  Future<bool> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? assignedTo,
    String? priority,
    String? status,
    DateTime? dueDate,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (assignedTo != null) body['assignedTo'] = assignedTo;
      if (priority != null) body['priority'] = priority;
      if (status != null) body['status'] = status;
      if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

      final response = await _apiClient.put('/tasks/$taskId', body: body);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Delete task
  Future<bool> deleteTask(String taskId) async {
    try {
      final response = await _apiClient.delete('/tasks/$taskId');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Fallback mock data method
  List<Task> _getMockTasks() {
    return [
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
        description:
            'Review and update company policies in the employee handbook',
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
  }

  // Legacy method - now uses API
  Future<List<Task>> getTasks() async {
    return await getAllTasks();
  }

  // Get tasks by employee
  Future<List<Task>> getTasksByEmployee(String employeeId) async {
    return await getAllTasks(assignedTo: employeeId, limit: 100);
  }

  // Get tasks by status
  Future<List<Task>> getTasksByStatus(String status) async {
    return await getAllTasks(status: status, limit: 100);
  }

  // Add task (legacy method - now uses createTask)
  Future<bool> addTask(Task task) async {
    return await createTask(
      title: task.title,
      description: task.description,
      assignedTo: task.assignedTo,
      priority: task.priority,
      status: task.status,
      dueDate: task.dueDate,
    );
  }

  // Update task status
  Future<bool> updateTaskStatus(String id, String status) async {
    return await updateTask(taskId: id, status: status);
  }

  // Get task statistics
  Future<Map<String, dynamic>> getTaskStats(String employeeId) async {
    try {
      final employeeTasks = await getTasksByEmployee(employeeId);

      final totalTasks = employeeTasks.length;
      final completedTasks = employeeTasks
          .where((task) => task.status == 'Completed')
          .length;
      final inProgressTasks = employeeTasks
          .where((task) => task.status == 'In Progress')
          .length;
      final todoTasks = employeeTasks
          .where((task) => task.status == 'Todo')
          .length;
      final overdueTasks = employeeTasks
          .where(
            (task) =>
                task.dueDate.isBefore(DateTime.now()) &&
                task.status != 'Completed',
          )
          .length;

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'inProgressTasks': inProgressTasks,
        'todoTasks': todoTasks,
        'overdueTasks': overdueTasks,
      };
    } catch (e) {
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'inProgressTasks': 0,
        'todoTasks': 0,
        'overdueTasks': 0,
      };
    }
  }
}
