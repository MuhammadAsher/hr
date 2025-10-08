import '../models/employee.dart';
import 'api_client.dart';

class ApiEmployeeService {
  final ApiClient _apiClient = ApiClient();

  // Get all employees
  Future<List<Employee>> getAllEmployees({
    int page = 1,
    int limit = 20,
    String? department,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (department != null) queryParams['department'] = department;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;

      final response = await _apiClient.get('/employees', queryParams: queryParams);

      if (response.isSuccess) {
        final List<dynamic> employeesData = response.data['data'] ?? [];
        return employeesData.map((json) => Employee.fromApiJson(json)).toList();
      } else {
        throw Exception(response.message ?? 'Failed to fetch employees');
      }
    } catch (e) {
      throw Exception('Failed to fetch employees: $e');
    }
  }

  // Get employee by ID
  Future<Employee?> getEmployeeById(String id) async {
    try {
      final response = await _apiClient.get('/employees/$id');

      if (response.isSuccess) {
        return Employee.fromApiJson(response.data['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(response.message ?? 'Failed to fetch employee');
      }
    } catch (e) {
      throw Exception('Failed to fetch employee: $e');
    }
  }

  // Create new employee
  Future<Employee> createEmployee({
    required String name,
    required String email,
    required String phone,
    required String department,
    required String position,
    required double salary,
    DateTime? joinDate,
    String status = 'Active',
    String? address,
    Map<String, dynamic>? emergencyContact,
    String? managerId,
  }) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'phone': phone,
        'department': department,
        'position': position,
        'salary': salary,
        'status': status.toLowerCase(),
        if (joinDate != null) 'joinDate': joinDate.toIso8601String(),
        if (address != null) 'address': address,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        if (managerId != null) 'managerId': managerId,
      };

      final response = await _apiClient.post('/employees', body: body);

      if (response.isSuccess) {
        return Employee.fromApiJson(response.data['data']);
      } else {
        throw Exception(response.message ?? 'Failed to create employee');
      }
    } catch (e) {
      throw Exception('Failed to create employee: $e');
    }
  }

  // Update employee
  Future<Employee> updateEmployee(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.put('/employees/$id', body: updates);

      if (response.isSuccess) {
        return Employee.fromApiJson(response.data['data']);
      } else {
        throw Exception(response.message ?? 'Failed to update employee');
      }
    } catch (e) {
      throw Exception('Failed to update employee: $e');
    }
  }

  // Delete employee
  Future<bool> deleteEmployee(String id) async {
    try {
      final response = await _apiClient.delete('/employees/$id');

      if (response.isSuccess || response.statusCode == 204) {
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to delete employee');
      }
    } catch (e) {
      throw Exception('Failed to delete employee: $e');
    }
  }

  // Search employees
  Future<List<Employee>> searchEmployees(String query) async {
    return getAllEmployees(search: query);
  }

  // Get employees by department
  Future<List<Employee>> getEmployeesByDepartment(String department) async {
    return getAllEmployees(department: department);
  }

  // Get active employees
  Future<List<Employee>> getActiveEmployees() async {
    return getAllEmployees(status: 'active');
  }
}
