import '../models/employee.dart';

class EmployeeService {
  // Mock data storage
  final List<Employee> _employees = [
    Employee(
      id: '1',
      name: 'John Doe',
      email: 'john.doe@hr.com',
      department: 'Engineering',
      position: 'Senior Developer',
      phone: '+1 234-567-8901',
      joinDate: DateTime(2020, 1, 15),
      salary: 85000,
      status: 'Active',
    ),
    Employee(
      id: '2',
      name: 'Jane Smith',
      email: 'jane.smith@hr.com',
      department: 'Marketing',
      position: 'Marketing Manager',
      phone: '+1 234-567-8902',
      joinDate: DateTime(2019, 6, 20),
      salary: 75000,
      status: 'Active',
    ),
    Employee(
      id: '3',
      name: 'Mike Johnson',
      email: 'mike.johnson@hr.com',
      department: 'Sales',
      position: 'Sales Executive',
      phone: '+1 234-567-8903',
      joinDate: DateTime(2021, 3, 10),
      salary: 65000,
      status: 'Active',
    ),
    Employee(
      id: '4',
      name: 'Sarah Williams',
      email: 'sarah.williams@hr.com',
      department: 'HR',
      position: 'HR Specialist',
      phone: '+1 234-567-8904',
      joinDate: DateTime(2020, 8, 5),
      salary: 60000,
      status: 'Active',
    ),
    Employee(
      id: '5',
      name: 'David Brown',
      email: 'david.brown@hr.com',
      department: 'Finance',
      position: 'Financial Analyst',
      phone: '+1 234-567-8905',
      joinDate: DateTime(2021, 11, 1),
      salary: 70000,
      status: 'Active',
    ),
  ];

  Future<List<Employee>> getAllEmployees() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_employees);
  }

  Future<Employee?> getEmployeeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _employees.firstWhere((emp) => emp.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _employees.add(employee);
    return true;
  }

  Future<bool> updateEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _employees.indexWhere((emp) => emp.id == employee.id);
    if (index != -1) {
      _employees[index] = employee;
      return true;
    }
    return false;
  }

  Future<bool> deleteEmployee(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _employees.indexWhere((emp) => emp.id == id);
    if (index != -1) {
      _employees.removeAt(index);
      return true;
    }
    return false;
  }

  Future<List<Employee>> searchEmployees(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.isEmpty) return getAllEmployees();
    
    return _employees.where((emp) {
      return emp.name.toLowerCase().contains(query.toLowerCase()) ||
          emp.email.toLowerCase().contains(query.toLowerCase()) ||
          emp.department.toLowerCase().contains(query.toLowerCase()) ||
          emp.position.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<List<Employee>> getEmployeesByDepartment(String department) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _employees.where((emp) => emp.department == department).toList();
  }
}

