import '../models/department.dart';
import '../models/employee.dart';
import 'employee_service.dart';

class DepartmentService {
  final EmployeeService _employeeService = EmployeeService();
  
  // Mock data storage
  final List<Department> _departments = [
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

  Future<List<Department>> getAllDepartments() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Update employee counts dynamically
    final employees = await _employeeService.getAllEmployees();
    
    for (var department in _departments) {
      final deptEmployees = employees.where((emp) => emp.department == department.name).length;
      final index = _departments.indexWhere((d) => d.id == department.id);
      if (index != -1) {
        _departments[index] = department.copyWith(employeeCount: deptEmployees);
      }
    }
    
    return List.from(_departments);
  }

  Future<Department?> getDepartmentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _departments.firstWhere((dept) => dept.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Employee>> getDepartmentEmployees(String departmentName) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final employees = await _employeeService.getAllEmployees();
    return employees.where((emp) => emp.department == departmentName).toList();
  }

  Future<bool> addDepartment(Department department) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _departments.add(department);
    return true;
  }

  Future<bool> updateDepartment(Department department) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _departments.indexWhere((dept) => dept.id == department.id);
    if (index != -1) {
      _departments[index] = department;
      return true;
    }
    return false;
  }

  Future<bool> deleteDepartment(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if department has employees
    final employees = await _employeeService.getAllEmployees();
    final department = await getDepartmentById(id);
    if (department != null) {
      final hasEmployees = employees.any((emp) => emp.department == department.name);
      if (hasEmployees) {
        return false; // Cannot delete department with employees
      }
    }
    
    _departments.removeWhere((dept) => dept.id == id);
    return true;
  }

  Future<List<String>> getDepartmentNames() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _departments.map((dept) => dept.name).toList();
  }

  Future<Map<String, dynamic>> getDepartmentStats() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final employees = await _employeeService.getAllEmployees();
    
    final stats = <String, dynamic>{};
    stats['totalDepartments'] = _departments.length;
    stats['totalEmployees'] = employees.length;
    stats['averageEmployeesPerDept'] = employees.length / _departments.length;
    
    // Department with most employees
    String largestDept = '';
    int maxEmployees = 0;
    
    for (var dept in _departments) {
      final deptEmployees = employees.where((emp) => emp.department == dept.name).length;
      if (deptEmployees > maxEmployees) {
        maxEmployees = deptEmployees;
        largestDept = dept.name;
      }
    }
    
    stats['largestDepartment'] = largestDept;
    stats['largestDepartmentCount'] = maxEmployees;
    
    return stats;
  }

  String generateDepartmentId() {
    final maxId = _departments.isEmpty 
        ? 0 
        : _departments.map((d) => int.tryParse(d.id) ?? 0).reduce((a, b) => a > b ? a : b);
    return (maxId + 1).toString();
  }
}
