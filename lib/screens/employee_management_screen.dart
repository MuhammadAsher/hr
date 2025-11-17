import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../services/api_employee_service.dart';
import '../services/error_service.dart';
import '../services/department_service.dart';
import '../services/organization_service.dart';
import '../providers/auth_provider.dart';
import '../constants/positions.dart';
import 'package:intl/intl.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final ApiEmployeeService _apiEmployeeService = ApiEmployeeService();
  List<Employee> _employees = [];
  bool _isLoading = true;
  bool _isLoadingEmployees = false; // Prevent concurrent requests
  DateTime? _lastLoadTime; // Track last load time
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer; // Debounce timer for search

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEmployees({bool force = false}) async {
    // Prevent concurrent requests
    if (_isLoadingEmployees && !force) {
      print('⏸️ Employees already loading, skipping...');
      return;
    }

    // Debounce: Don't load if loaded within last 2 seconds (unless forced)
    if (!force && _lastLoadTime != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastLoadTime!);
      if (timeSinceLastLoad.inSeconds < 2) {
        print('⏸️ Employees loaded recently (${timeSinceLastLoad.inSeconds}s ago), skipping...');
        return;
      }
    }

    _isLoadingEmployees = true;
    _lastLoadTime = DateTime.now();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final employees = await _apiEmployeeService.getAllEmployees();
      setState(() {
        _employees = employees;
        _isLoading = false;
        _isLoadingEmployees = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('❌ Failed to load employees: $e');
      setState(() {
        _isLoading = false;
        _isLoadingEmployees = false;
        _errorMessage = e.toString();
      });
      
      // Show error alert
      ErrorService.showErrorAlert(
        title: 'Failed to Load Employees',
        message: e.toString().replaceAll('Exception: ', ''),
        error: 'API Error',
        onOk: () {
          // Optionally retry on OK
        },
      );
    }
  }

  Future<void> _searchEmployees(String query) async {
    if (query.isEmpty) {
      _loadEmployees(force: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Use API search
      final employees = await _apiEmployeeService.searchEmployees(query);
      setState(() {
        _employees = employees;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('❌ Failed to search employees: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      ErrorService.showErrorSnackbar(
        message: 'Failed to search employees: ${e.toString().replaceAll('Exception: ', '')}',
        error: 'Search Error',
      );
    }
  }

  Future<void> _toggleEmployeeStatus(Employee employee) async {
    final isActive = employee.status.toLowerCase() == 'active';
    final action = isActive ? 'deactivate' : 'activate';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm ${action == 'activate' ? 'Activation' : 'Deactivation'}'),
        content: Text(
          'Are you sure you want to $action "${employee.name}"? '
          '${isActive ? 'The employee will not be able to access the system.' : 'The employee will be able to access the system again.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              action == 'activate' ? 'Activate' : 'Deactivate',
              style: TextStyle(
                color: isActive ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await _apiEmployeeService.toggleEmployeeStatus(employee.id);
        _loadEmployees(force: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Employee ${action}d successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Failed to toggle employee status: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to $action employee: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
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
        await _apiEmployeeService.deleteEmployee(id);
        _loadEmployees(force: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Failed to delete employee: $e');
        ErrorService.showErrorAlert(
          title: 'Failed to Delete Employee',
          message: e.toString().replaceAll('Exception: ', ''),
          error: 'Delete Error',
        );
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
            onPressed: () async {
              // Check if departments exist before allowing employee creation
              final departmentService = DepartmentService();
              try {
                final departments = await departmentService.getAllDepartments();
                if (departments.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please create a department first before adding employees'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  return;
                }
              } catch (e) {
                print('❌ Error checking departments: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error checking departments: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditEmployeeScreen(),
                  ),
                ).then((_) => _loadEmployees(force: true));
              }
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
              onChanged: (query) {
                // Cancel previous timer
                _searchDebounceTimer?.cancel();
                
                // Debounce search - wait 500ms after user stops typing
                _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
                  _searchEmployees(query);
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load employees',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _errorMessage!.replaceAll('Exception: ', ''),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _loadEmployees(force: true),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _employees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No employees found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first employee to get started',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
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
                            itemBuilder: (context) {
                              final isActive = employee.status.toLowerCase() == 'active';
                              return [
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
                                PopupMenuItem(
                                  value: 'toggle_status',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive ? Icons.block : Icons.check_circle,
                                        size: 20,
                                        color: isActive ? Colors.orange : Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isActive ? 'Deactivate' : 'Activate',
                                        style: TextStyle(
                                          color: isActive ? Colors.orange : Colors.green,
                                        ),
                                      ),
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
                              ];
                            },
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
                                ).then((_) => _loadEmployees(force: true));
                              } else if (value == 'toggle_status') {
                                _toggleEmployeeStatus(employee);
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
  final _joinDateController = TextEditingController();

  final DepartmentService _departmentService = DepartmentService();
  final OrganizationService _organizationService = OrganizationService();
  String? _selectedDepartment;
  List<String> _departments = [];
  bool _isLoadingDepartments = true;
  
  String? _organizationName;
  bool _isLoadingOrganization = true;

  String? _selectedPosition;
  bool _isCustomPosition = false;
  final List<String> _availablePositions = EmployeePositions.allPositions;
  final TextEditingController _searchPositionController = TextEditingController();
  List<String> _filteredPositions = EmployeePositions.allPositions;
  
  DateTime? _selectedJoinDate;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadOrganizationName();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _emailController.text = widget.employee!.email;
      _phoneController.text = widget.employee!.phone;
      _positionController.text = widget.employee!.position;
      _salaryController.text = widget.employee!.salary.toString();
      _selectedDepartment = widget.employee!.department;
      
      // Set join date if available
      if (widget.employee!.joinDate != null) {
        _selectedJoinDate = widget.employee!.joinDate;
        _joinDateController.text = DateFormat('yyyy-MM-dd').format(widget.employee!.joinDate!);
      }
      
      // Check if position is in predefined list
      if (EmployeePositions.isPredefined(widget.employee!.position)) {
        _selectedPosition = widget.employee!.position;
        _isCustomPosition = false;
      } else {
        _isCustomPosition = true;
        _selectedPosition = 'Custom';
      }
    } else {
      // Set default join date to today for new employees
      _selectedJoinDate = DateTime.now();
      _joinDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoadingDepartments = true;
    });
    
    try {
      final departments = await _departmentService.getAllDepartments();
      final departmentNames = departments.map((dept) => dept.name).toList();
      
      setState(() {
        _departments = departmentNames;
        _isLoadingDepartments = false;
        // Set default department if not set and departments are available
        if (_selectedDepartment == null && _departments.isNotEmpty) {
          _selectedDepartment = _departments.first;
        }
        // If editing and department exists in list, keep it; otherwise add it
        if (widget.employee != null && 
            !_departments.contains(widget.employee!.department)) {
          _departments.add(widget.employee!.department);
        }
      });
    } catch (e) {
      print('❌ Failed to load departments: $e');
      // Fallback to default departments if API fails
      setState(() {
        _departments = [
          'Engineering',
          'Marketing',
          'Sales',
          'HR',
          'Finance',
          'Operations',
        ];
        _isLoadingDepartments = false;
        if (_selectedDepartment == null && _departments.isNotEmpty) {
          _selectedDepartment = _departments.first;
        }
      });
    }
  }

  Future<void> _loadOrganizationName() async {
    setState(() {
      _isLoadingOrganization = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        // First, try to get organization name from user object (from login response)
        if (user.organizationName != null && user.organizationName!.isNotEmpty) {
          setState(() {
            _organizationName = user.organizationName;
            _isLoadingOrganization = false;
          });
          return;
        }
        
        // If not available in user object, try to fetch from API
        if (user.organizationId.isNotEmpty) {
          try {
            final organization = await _organizationService.getOrganizationById(user.organizationId);
            setState(() {
              _organizationName = organization?.name ?? 'Your Organization';
              _isLoadingOrganization = false;
            });
          } catch (e) {
            print('⚠️ Could not fetch organization name from API: $e');
            // Fallback to generic message
            setState(() {
              _organizationName = 'Your Organization';
              _isLoadingOrganization = false;
            });
          }
        } else {
          setState(() {
            _organizationName = 'Your Organization';
            _isLoadingOrganization = false;
          });
        }
      } else {
        setState(() {
          _organizationName = 'Your Organization';
          _isLoadingOrganization = false;
        });
      }
    } catch (e) {
      print('❌ Error loading organization name: $e');
      setState(() {
        _organizationName = 'Your Organization';
        _isLoadingOrganization = false;
      });
    }
  }

  Future<void> _selectJoinDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoinDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Join Date',
    );
    
    if (picked != null && picked != _selectedJoinDate) {
      setState(() {
        _selectedJoinDate = picked;
        _joinDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _joinDateController.dispose();
    _searchPositionController.dispose();
    super.dispose();
  }

  void _showPositionPicker(BuildContext context) {
    // Reset search when opening
    _searchPositionController.clear();
    _filteredPositions = _availablePositions;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Select Position',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Search field
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchPositionController,
                    decoration: InputDecoration(
                      hintText: 'Search positions...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        if (value.isEmpty) {
                          _filteredPositions = _availablePositions;
                        } else {
                          _filteredPositions = _availablePositions
                              .where((position) => position
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        }
                      });
                    },
                  ),
                ),
                // Positions list
                Expanded(
                  child: _filteredPositions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No positions found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try a different search term',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _filteredPositions.length + 1, // +1 for Custom option
                          itemBuilder: (context, index) {
                            if (index == _filteredPositions.length) {
                              // Custom option at the end
                              return ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Custom (Enter manually)'),
                                trailing: _isCustomPosition 
                                    ? const Icon(Icons.check, color: Colors.blue)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _isCustomPosition = true;
                                    _selectedPosition = 'Custom';
                                    _positionController.clear();
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            }
                            
                            final position = _filteredPositions[index];
                            final isSelected = !_isCustomPosition && _selectedPosition == position;
                            
                            return ListTile(
                              title: Text(position),
                              trailing: isSelected 
                                  ? const Icon(Icons.check, color: Colors.blue)
                                  : null,
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  _isCustomPosition = false;
                                  _selectedPosition = position;
                                  _positionController.text = position;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveEmployee() async {
    // Validate position field first
    String? positionError;
    if (_isCustomPosition && _positionController.text.trim().isEmpty) {
      positionError = 'Please enter a custom position';
    } else if (!_isCustomPosition && _selectedPosition == null) {
      positionError = 'Please select a position';
    }
    
    if (positionError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(positionError),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      try {
        final apiEmployeeService = ApiEmployeeService();

        // Get the final position value
        final String positionValue = _isCustomPosition 
            ? _positionController.text.trim()
            : (_selectedPosition ?? _positionController.text.trim());

        if (widget.employee == null) {
          // Validate department is selected
          if (_selectedDepartment == null || _selectedDepartment!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a department'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          // Create new employee via API
          print('🚀 Creating new employee via API...');
          final newEmployee = await apiEmployeeService.createEmployee(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            department: _selectedDepartment!,
            position: positionValue,
            salary: double.parse(_salaryController.text),
            joinDate: _selectedJoinDate ?? DateTime.now(),
            status: 'active',
          );
          print('✅ Employee created successfully: ${newEmployee.id}');
        } else {
          // Validate department is selected
          if (_selectedDepartment == null || _selectedDepartment!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a department'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          // Update existing employee via API
          print('🚀 Updating employee via API...');
          final updates = {
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'department': _selectedDepartment!,
            'position': positionValue,
            'salary': double.parse(_salaryController.text),
            'status': widget.employee!.status.toLowerCase(),
            if (_selectedJoinDate != null) 'joinDate': _selectedJoinDate!.toIso8601String(),
          };
          final updatedEmployee = await apiEmployeeService.updateEmployee(
            widget.employee!.id,
            updates,
          );
          print('✅ Employee updated successfully: ${updatedEmployee.id}');
        }

        if (mounted) {
          Navigator.pop(context);
          if (widget.employee == null) {
            // Show success dialog with account creation info
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Employee Added Successfully'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Employee has been added to your organization.'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, 
                                color: Colors.blue[900], 
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Account Created',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A user account has been created for this employee with:',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Email: ${_emailController.text.trim()}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Default Password: employee123',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The employee can reset their password from the app.',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Employee updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Failed to save employee: $e');
        if (mounted) {
          ErrorService.showErrorAlert(
            title: widget.employee == null
                ? 'Failed to Add Employee'
                : 'Failed to Update Employee',
            message: e.toString().replaceAll('Exception: ', ''),
            error: 'Save Error',
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
            // Organization Name (Read-only, not clickable)
            _isLoadingOrganization
                ? const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : TextFormField(
                    initialValue: _organizationName ?? 'Your Organization',
                    decoration: InputDecoration(
                      labelText: 'Organization',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.business),
                      filled: true,
                      fillColor: Colors.grey[100],
                      helperText: 'Employee will be added to this organization',
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
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
            _isLoadingDepartments
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Department *',
                      border: OutlineInputBorder(),
                      helperText: 'Select department from your organization',
                    ),
                    items: _departments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept,
                        child: Text(dept),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a department';
                      }
                      return null;
                    },
                  ),
            const SizedBox(height: 16),
            // Position Field with Bottom Sheet Picker
            InkWell(
              onTap: () => _showPositionPicker(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Position',
                  border: const OutlineInputBorder(),
                  helperText: 'Tap to select a position or enter custom',
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _isCustomPosition 
                      ? (_positionController.text.isEmpty 
                          ? 'Select or enter position' 
                          : _positionController.text)
                      : (_selectedPosition ?? 'Select position'),
                  style: TextStyle(
                    color: (_isCustomPosition && _positionController.text.isEmpty) || 
                           (!_isCustomPosition && _selectedPosition == null)
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
              ),
            ),
            // Custom Position TextField (shown when Custom is selected)
            if (_isCustomPosition) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Custom Position',
                  border: OutlineInputBorder(),
                  helperText: 'Enter the position name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a position';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Update the selected position when user types
                  setState(() {});
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _salaryController,
              decoration: const InputDecoration(
                labelText: 'Salary *',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter salary';
                if (double.tryParse(value!) == null) {
                  return 'Please enter valid salary';
                }
                if (double.parse(value) < 0) {
                  return 'Salary cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _joinDateController,
              decoration: InputDecoration(
                labelText: 'Join Date *',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
                helperText: 'Select the date when employee joined',
              ),
              readOnly: true,
              onTap: () => _selectJoinDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select join date';
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
