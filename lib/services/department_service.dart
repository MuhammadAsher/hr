import '../models/department.dart';
import '../models/employee.dart';
import 'employee_service.dart';
import 'api_client.dart';

class DepartmentService {
  final ApiClient _apiClient = ApiClient();
  final EmployeeService _employeeService = EmployeeService();

  // Get all departments
  Future<List<Department>> getAllDepartments({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        '/departments',
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        final responseData = response.data['data'];
        final List<dynamic> departments = responseData['departments'] ?? [];
        return departments.map((json) => Department.fromJson(json)).toList();
      } else {
        throw Exception(response.message ?? 'Failed to fetch departments');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockDepartments();
    }
  }

  // Get department by ID
  Future<Department?> getDepartmentById(String departmentId) async {
    try {
      final response = await _apiClient.get('/departments/$departmentId');

      if (response.isSuccess) {
        return Department.fromJson(response.data['data']);
      } else {
        throw Exception(response.message ?? 'Failed to fetch department');
      }
    } catch (e) {
      // Fallback to mock data
      final mockDepartments = _getMockDepartments();
      return mockDepartments.firstWhere(
        (dept) => dept.id == departmentId,
        orElse: () => mockDepartments.first,
      );
    }
  }

  // Create new department (Admin only)
  Future<bool> createDepartment({
    required String name,
    String? description,
    String? managerId,
    double? budget,
  }) async {
    try {
      final body = <String, dynamic>{'name': name};

      if (description != null) body['description'] = description;
      if (managerId != null) body['managerId'] = managerId;
      if (budget != null) body['budget'] = budget;

      final response = await _apiClient.post('/departments', body: body);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Update department (Admin only)
  Future<bool> updateDepartment({
    required String departmentId,
    String? name,
    String? description,
    String? managerId,
    double? budget,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (managerId != null) body['managerId'] = managerId;
      if (budget != null) body['budget'] = budget;

      final response = await _apiClient.put(
        '/departments/$departmentId',
        body: body,
      );
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Delete department (Admin only)
  Future<bool> deleteDepartment(String departmentId) async {
    try {
      final response = await _apiClient.delete('/departments/$departmentId');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Fallback mock data method
  List<Department> _getMockDepartments() {
    return [
      Department(
        id: '1',
        name: 'Engineering',
        description: 'Software development and technical operations',
        managerId: '1',
        managerName: 'John Doe',
        employeeCount: 15,
      ),
      Department(
        id: '2',
        name: 'Marketing',
        description: 'Brand promotion and customer acquisition',
        managerId: '2',
        managerName: 'Jane Smith',
        employeeCount: 8,
      ),
      Department(
        id: '3',
        name: 'Sales',
        description: 'Revenue generation and client relations',
        managerId: '3',
        managerName: 'Mike Johnson',
        employeeCount: 12,
      ),
      Department(
        id: '4',
        name: 'HR',
        description: 'Human resources and employee relations',
        managerId: '4',
        managerName: 'Sarah Williams',
        employeeCount: 5,
      ),
      Department(
        id: '5',
        name: 'Finance',
        description: 'Financial planning and accounting',
        managerId: '5',
        managerName: 'David Brown',
        employeeCount: 6,
      ),
      Department(
        id: '6',
        name: 'Operations',
        description: 'Business operations and process management',
        managerId: '1',
        managerName: 'John Doe',
        employeeCount: 10,
      ),
      Department(
        id: '7',
        name: 'IT Support',
        description: 'Technical support and infrastructure',
        managerId: '1',
        managerName: 'John Doe',
        employeeCount: 4,
      ),
      Department(
        id: '8',
        name: 'Legal',
        description: 'Legal compliance and contract management',
        managerId: '4',
        managerName: 'Sarah Williams',
        employeeCount: 3,
      ),
    ];
  }

  // Legacy method - now uses API
  Future<List<Department>> getDepartments() async {
    return await getAllDepartments();
  }

  // Get department names only
  Future<List<String>> getDepartmentNames() async {
    try {
      final departments = await getAllDepartments(limit: 100);
      return departments.map((dept) => dept.name).toList();
    } catch (e) {
      final mockDepartments = _getMockDepartments();
      return mockDepartments.map((dept) => dept.name).toList();
    }
  }

  // Get employees in a specific department
  Future<List<Employee>> getDepartmentEmployees(String departmentName) async {
    try {
      final allEmployees = await _employeeService.getAllEmployees();
      return allEmployees
          .where((emp) => emp.department == departmentName)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Add department (legacy method - now uses createDepartment)
  Future<bool> addDepartment(Department department) async {
    return await createDepartment(
      name: department.name,
      description: department.description,
      managerId: department.managerId,
    );
  }

  // Update department (legacy method - now uses updateDepartment with ID)
  Future<bool> updateDepartmentLegacy(Department department) async {
    return await updateDepartment(
      departmentId: department.id,
      name: department.name,
      description: department.description,
      managerId: department.managerId,
    );
  }

  // Get department statistics
  Future<Map<String, dynamic>> getDepartmentStats() async {
    try {
      final departments = await getAllDepartments(limit: 100);

      final totalDepartments = departments.length;
      final totalEmployees = departments.fold<int>(
        0,
        (sum, dept) => sum + dept.employeeCount,
      );

      final avgEmployeesPerDept = totalDepartments > 0
          ? (totalEmployees / totalDepartments).toStringAsFixed(1)
          : '0.0';

      // Find largest and smallest departments
      final sortedBySize = List<Department>.from(departments)
        ..sort((a, b) => b.employeeCount.compareTo(a.employeeCount));

      return {
        'totalDepartments': totalDepartments,
        'totalEmployees': totalEmployees,
        'averageEmployeesPerDepartment': avgEmployeesPerDept,
        'largestDepartment': sortedBySize.isNotEmpty
            ? sortedBySize.first.name
            : 'N/A',
        'smallestDepartment': sortedBySize.isNotEmpty
            ? sortedBySize.last.name
            : 'N/A',
      };
    } catch (e) {
      return {
        'totalDepartments': 0,
        'totalEmployees': 0,
        'averageEmployeesPerDepartment': '0.0',
        'largestDepartment': 'N/A',
        'smallestDepartment': 'N/A',
      };
    }
  }

  // Generate department ID (legacy method)
  String generateDepartmentId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
