import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/payslip.dart';
import '../services/api_employee_service.dart';
import '../services/payslip_service.dart';
import '../services/error_service.dart';

class PayslipManagementScreen extends StatefulWidget {
  const PayslipManagementScreen({super.key});

  @override
  State<PayslipManagementScreen> createState() => _PayslipManagementScreenState();
}

class _PayslipManagementScreenState extends State<PayslipManagementScreen> {
  final ApiEmployeeService _employeeService = ApiEmployeeService();
  final PayslipService _payslipService = PayslipService();

  final List<String> _months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<Employee> _employees = [];
  String? _selectedEmployeeId;
  bool _isInitialLoading = true;
  bool _isPayslipLoading = false;

  List<Payslip> _payslips = [];
  List<Payslip> _filteredPayslips = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isInitialLoading = true);
    try {
      final employees = await _employeeService.getAllEmployees(limit: 1000);
      if (!mounted) return;
      setState(() {
        _employees = employees;
        if (employees.isNotEmpty) {
          _selectedEmployeeId = employees.first.id;
        }
        _isInitialLoading = false;
      });
      if (_selectedEmployeeId != null) {
        await _loadPayslips();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitialLoading = false);
      ErrorService.showErrorSnackbar(
        message: 'Failed to load employees',
        error: e.toString(),
      );
    }
  }

  Future<void> _loadPayslips() async {
    if (_selectedEmployeeId == null) return;
    setState(() => _isPayslipLoading = true);
    try {
      final payslips = await _payslipService.getAllPayslips(
        employeeId: _selectedEmployeeId,
        limit: 200,
      );
      if (!mounted) return;
      setState(() {
        _payslips = payslips;
        _applyFilters();
        _isPayslipLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPayslipLoading = false);
      ErrorService.showErrorSnackbar(
        message: 'Failed to load payslips',
        error: e.toString(),
      );
    }
  }

  Future<void> _finalizePayslip(Payslip payslip) async {
    try {
      final success = await _payslipService.finalizePayslip(payslip.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payslip finalized successfully')),
          );
        }
        await _loadPayslips();
      } else {
        ErrorService.showErrorSnackbar(
          message: 'Failed to finalize payslip',
          error: 'Finalize Error',
        );
      }
    } catch (e) {
      ErrorService.showErrorSnackbar(
        message: 'Failed to finalize payslip',
        error: e.toString(),
      );
    }
  }

  Future<void> _deletePayslip(Payslip payslip) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payslip'),
        content: const Text('Are you sure you want to delete this payslip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmation != true) return;

    try {
      final success = await _payslipService.deletePayslip(payslip.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payslip deleted successfully')),
          );
        }
        await _loadPayslips();
      } else {
        ErrorService.showErrorSnackbar(
          message: 'Failed to delete payslip',
          error: 'Delete Error',
        );
      }
    } catch (e) {
      ErrorService.showErrorSnackbar(
        message: 'Failed to delete payslip',
        error: e.toString(),
      );
    }
  }

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPayslips = List.from(_payslips);
      } else {
        _filteredPayslips = _payslips.where((payslip) {
          final monthMatch = payslip.month.toLowerCase().contains(query);
          final statusMatch = payslip.status.toLowerCase().contains(query);
          final noteMatch = (payslip.notes ?? '').toLowerCase().contains(query);
          final currencyMatch = payslip.currency.toLowerCase().contains(query);
          final yearMatch = payslip.year.toString().contains(query);
          return monthMatch || statusMatch || noteMatch || currencyMatch || yearMatch;
        }).toList();
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _applyFilters();
  }

  void _onEmployeeChanged(String? id) {
    if (id == null) return;
    setState(() {
      _selectedEmployeeId = id;
    });
    _loadPayslips();
  }

  Employee? get _selectedEmployee {
    if (_selectedEmployeeId == null) return null;
    return _employees.firstWhere(
      (employee) => employee.id == _selectedEmployeeId,
      orElse: () => _employees.isNotEmpty ? _employees.first : Employee(
        id: '',
        name: '',
        email: '',
        department: '',
        position: '',
        phone: '',
        joinDate: DateTime.now(),
        salary: 0,
      ),
    );
  }

  Future<void> _showCreatePayslipSheet() async {
    if (_employees.isEmpty) {
      ErrorService.showErrorSnackbar(
        message: 'No employees found. Please add employees first.',
        error: 'Validation Error',
      );
      return;
    }

    final initialEmployeeId = _selectedEmployeeId ?? _employees.first.id;
    final salary = _employees
        .firstWhere((employee) => employee.id == initialEmployeeId, orElse: () => _employees.first)
        .salary
        .toStringAsFixed(2);

    final basicSalaryController = TextEditingController(text: salary);
    final allowancesController = TextEditingController();
    final deductionsController = TextEditingController();
    final overtimeController = TextEditingController();
    final bonusController = TextEditingController();
    final notesController = TextEditingController();

    String selectedEmployeeId = initialEmployeeId;
    String selectedMonth = _months[DateTime.now().month - 1];
    int selectedYear = DateTime.now().year;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Generate Payslip',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedEmployeeId,
                  items: _employees
                      .map(
                        (employee) => DropdownMenuItem(
                          value: employee.id,
                          child: Text(employee.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() {
                      selectedEmployeeId = value;
                      final employee = _employees.firstWhere((e) => e.id == value);
                      basicSalaryController.text = employee.salary.toStringAsFixed(2);
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Employee',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMonth,
                        items: _months
                            .map((month) => DropdownMenuItem(
                                  value: month,
                                  child: Text(month),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedMonth = value);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        items: List<int>.generate(5, (index) => DateTime.now().year - 2 + index)
                            .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedYear = value);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNumberField(basicSalaryController, 'Basic Salary', isRequired: true),
                const SizedBox(height: 12),
                _buildNumberField(allowancesController, 'Allowances'),
                const SizedBox(height: 12),
                _buildNumberField(overtimeController, 'Overtime'),
                const SizedBox(height: 12),
                _buildNumberField(bonusController, 'Bonus'),
                const SizedBox(height: 12),
                _buildNumberField(deductionsController, 'Deductions'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final basicSalary = double.tryParse(basicSalaryController.text.trim()) ?? 0;
                            if (basicSalary <= 0) {
                              ErrorService.showErrorSnackbar(
                                message: 'Please enter a valid basic salary',
                                error: 'Validation Error',
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            final allowances = double.tryParse(allowancesController.text.trim()) ?? 0;
                            final deductions = double.tryParse(deductionsController.text.trim()) ?? 0;
                            final overtime = double.tryParse(overtimeController.text.trim()) ?? 0;
                            final bonus = double.tryParse(bonusController.text.trim()) ?? 0;

                            final success = await _payslipService.createPayslip(
                              employeeId: selectedEmployeeId,
                              month: selectedMonth,
                              year: selectedYear.toString(),
                              basicSalary: basicSalary,
                              allowances: allowances,
                              deductions: deductions,
                              overtime: overtime,
                              bonus: bonus,
                              allowanceBreakdown: {
                                if (allowances > 0) 'Allowances': allowances,
                                if (overtime > 0) 'Overtime': overtime,
                                if (bonus > 0) 'Bonus': bonus,
                              },
                              deductionBreakdown: {
                                if (deductions > 0) 'Deductions': deductions,
                              },
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );

                            if (success) {
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Payslip generated successfully')),
                                );
                              }
                              await _loadPayslips();
                            } else {
                              ErrorService.showErrorSnackbar(
                                message: 'Failed to generate payslip',
                                error: 'Generation Error',
                              );
                            }

                            if (mounted) {
                              setModalState(() => isSubmitting = false);
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.receipt_long),
                    label: Text(isSubmitting ? 'Generating...' : 'Generate Payslip'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _buildNumberField(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              if (double.tryParse(value.trim()) == null) {
                return 'Enter a valid number';
              }
              return null;
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslip Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePayslipSheet,
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: DropdownButtonFormField<String>(
                    value: _selectedEmployeeId,
                    items: _employees
                        .map((employee) => DropdownMenuItem(
                              value: employee.id,
                              child: Text(employee.name),
                            ))
                        .toList(),
                    onChanged: _onEmployeeChanged,
                    decoration: const InputDecoration(
                      labelText: 'Select Employee',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search payslips by month, status, year...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPayslips,
                    child: _isPayslipLoading
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                            ],
                          )
                        : _filteredPayslips.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(
                                    height: 200,
                                    child: Center(child: Text('No payslips available')),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredPayslips.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final payslip = _filteredPayslips[index];
                                  return Card(
                                    elevation: 1,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                                        child: Icon(
                                          Icons.receipt_long,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      title: Text('${payslip.month} ${payslip.year}'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('Net Salary: ${payslip.currency} ${payslip.netSalary.toStringAsFixed(2)}'),
                                          if (payslip.notes != null && payslip.notes!.isNotEmpty)
                                            Text(
                                              payslip.notes!,
                                              style: const TextStyle(color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _statusColor(payslip.status).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              payslip.status,
                                              style: TextStyle(
                                                color: _statusColor(payslip.status),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (payslip.status.toLowerCase() == 'draft')
                                            IconButton(
                                              icon: const Icon(Icons.verified_outlined),
                                              tooltip: 'Finalize payslip',
                                              onPressed: () => _finalizePayslip(payslip),
                                            ),
                                          if (payslip.status.toLowerCase() == 'draft')
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline),
                                              tooltip: 'Delete payslip',
                                              onPressed: () => _deletePayslip(payslip),
                                            ),
                                        ],
                                      ),
                                      onTap: () => _showPayslipDetails(payslip),
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processed':
      case 'paid':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  void _showPayslipDetails(Payslip payslip) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${payslip.month} ${payslip.year}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text('Employee: ${payslip.employeeName}'),
              Text('Net Salary: ${payslip.currency} ${payslip.netSalary.toStringAsFixed(2)}'),
              if (payslip.payPeriodStart != null && payslip.payPeriodEnd != null)
                Text(
                  'Period: ${DateFormat('MMM dd').format(payslip.payPeriodStart!)} - '
                  '${DateFormat('MMM dd, yyyy').format(payslip.payPeriodEnd!)}',
                ),
              const Divider(height: 32),
              Text('Allowances', style: Theme.of(context).textTheme.titleMedium),
              if (payslip.allowanceBreakdown.isEmpty)
                const Text('No allowances recorded'),
              ...payslip.allowanceBreakdown.entries.map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  trailing: Text('${payslip.currency} ${entry.value.toStringAsFixed(2)}'),
                ),
              ),
              const Divider(height: 32),
              Text('Deductions', style: Theme.of(context).textTheme.titleMedium),
              if (payslip.deductionBreakdown.isEmpty)
                const Text('No deductions recorded'),
              ...payslip.deductionBreakdown.entries.map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  trailing: Text('${payslip.currency} ${entry.value.toStringAsFixed(2)}'),
                ),
              ),
              const Divider(height: 32),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              Text(payslip.notes?.isNotEmpty == true ? payslip.notes! : 'No notes provided'),
            ],
          ),
        ),
      ),
    );
  }
}
