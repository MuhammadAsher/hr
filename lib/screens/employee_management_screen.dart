import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';
import '../services/api_employee_service.dart';
import 'package:intl/intl.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final EmployeeService _employeeService =
      EmployeeService(); // Fallback for mock data
  final ApiEmployeeService _apiEmployeeService =
      ApiEmployeeService(); // API service
  List<Employee> _employees = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      // Try API first
      final employees = await _apiEmployeeService.getAllEmployees();
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      print('API failed, falling back to mock data: $e');
      // Fallback to mock data
      final employees = await _employeeService.getAllEmployees();
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchEmployees(String query) async {
    setState(() => _isLoading = true);
    try {
      // For now, just reload all employees and filter locally
      // TODO: Implement search in API service
      final employees = await _apiEmployeeService.getAllEmployees();
      final filteredEmployees = employees.where((emp) {
        return emp.name.toLowerCase().contains(query.toLowerCase()) ||
            emp.email.toLowerCase().contains(query.toLowerCase()) ||
            emp.department.toLowerCase().contains(query.toLowerCase()) ||
            emp.position.toLowerCase().contains(query.toLowerCase());
      }).toList();
      setState(() {
        _employees = filteredEmployees;
        _isLoading = false;
      });
    } catch (e) {
      print('API search failed, falling back to mock data: $e');
      // Fallback to mock data
      final employees = await _employeeService.searchEmployees(query);
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEmployee(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Try API first
        await _apiEmployeeService.deleteEmployee(id);
        _loadEmployees();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('API delete failed, falling back to mock data: $e');
        // Fallback to mock service
        await _employeeService.deleteEmployee(id);
        _loadEmployees();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee deleted (using mock data)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditEmployeeScreen(),
                ),
              ).then((_) => _loadEmployees());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadEmployees();
                        },
                      )
                    : null,
              ),
              onChanged: _searchEmployees,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _employees.isEmpty
                ? const Center(child: Text('No employees found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              employee.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            employee.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(employee.position),
                              Text(
                                employee.department,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 20),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'view') {
                                _showEmployeeDetails(employee);
                              } else if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditEmployeeScreen(
                                      employee: employee,
                                    ),
                                  ),
                                ).then((_) => _loadEmployees());
                              } else if (value == 'delete') {
                                _deleteEmployee(employee.id);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', employee.email),
              _buildDetailRow('Phone', employee.phone),
              _buildDetailRow('Department', employee.department),
              _buildDetailRow('Position', employee.position),
              _buildDetailRow(
                'Join Date',
                DateFormat('MMM dd, yyyy').format(employee.joinDate),
              ),
              _buildDetailRow(
                'Salary',
                '\$${employee.salary.toStringAsFixed(2)}',
              ),
              _buildDetailRow('Status', employee.status),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class AddEditEmployeeScreen extends StatefulWidget {
  final Employee? employee;

  const AddEditEmployeeScreen({super.key, this.employee});

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  final _salaryController = TextEditingController();

  String _selectedDepartment = 'Engineering';
  final List<String> _departments = [
    'Engineering',
    'Marketing',
    'Sales',
    'HR',
    'Finance',
    'Operations',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _emailController.text = widget.employee!.email;
      _phoneController.text = widget.employee!.phone;
      _positionController.text = widget.employee!.position;
      _salaryController.text = widget.employee!.salary.toString();
      _selectedDepartment = widget.employee!.department;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      try {
        final apiEmployeeService = ApiEmployeeService();

        if (widget.employee == null) {
          // Create new employee via API
          print('🚀 Creating new employee via API...');
          final newEmployee = await apiEmployeeService.createEmployee(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            department: _selectedDepartment,
            position: _positionController.text,
            salary: double.parse(_salaryController.text),
            joinDate: DateTime.now(),
            status: 'Active',
          );
          print('✅ Employee created successfully: ${newEmployee.id}');
        } else {
          // Update existing employee via API
          print('🚀 Updating employee via API...');
          final updates = {
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'department': _selectedDepartment,
            'position': _positionController.text,
            'salary': double.parse(_salaryController.text),
            'status': widget.employee!.status.toLowerCase(),
          };
          final updatedEmployee = await apiEmployeeService.updateEmployee(
            widget.employee!.id,
            updates,
          );
          print('✅ Employee updated successfully: ${updatedEmployee.id}');
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.employee == null
                    ? 'Employee added successfully'
                    : 'Employee updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ API call failed: $e');
        // Fallback to mock service for development
        final employeeService = EmployeeService();
        final employee = Employee(
          id:
              widget.employee?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          department: _selectedDepartment,
          position: _positionController.text,
          salary: double.parse(_salaryController.text),
          joinDate: widget.employee?.joinDate ?? DateTime.now(),
          status: widget.employee?.status ?? 'Active',
        );

        if (widget.employee == null) {
          await employeeService.addEmployee(employee);
        } else {
          await employeeService.updateEmployee(employee);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.employee == null ? 'Employee added' : 'Employee updated'} (using mock data)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter email';
                if (!value!.contains('@')) return 'Please enter valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter phone' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartment,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              items: _departments.map((dept) {
                return DropdownMenuItem(value: dept, child: Text(dept));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDepartment = value!);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: 'Position',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter position' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _salaryController,
              decoration: const InputDecoration(
                labelText: 'Salary',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter salary';
                if (double.tryParse(value!) == null) {
                  return 'Please enter valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveEmployee,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.employee == null ? 'Add Employee' : 'Update Employee',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
