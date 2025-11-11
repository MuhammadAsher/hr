import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/pdf_service.dart';
import '../services/employee_service.dart';
import '../services/department_service.dart';
import '../services/payslip_service.dart';
import '../models/employee.dart';
import '../models/payslip.dart';
import '../models/department.dart';

class PdfGenerationScreen extends StatefulWidget {
  const PdfGenerationScreen({super.key});

  @override
  State<PdfGenerationScreen> createState() => _PdfGenerationScreenState();
}

class _PdfGenerationScreenState extends State<PdfGenerationScreen> {
  final PdfService _pdfService = PdfService();
  final EmployeeService _employeeService = EmployeeService();
  final DepartmentService _departmentService = DepartmentService();
  final PayslipService _payslipService = PayslipService();

  bool _isGenerating = false;

  Future<void> _generateEmployeeReport() async {
    setState(() => _isGenerating = true);

    try {
      final employees = await _employeeService.getAllEmployees();
      final pdfBytes = await _pdfService.generateEmployeeReport(employees);

      // Show options dialog
      if (mounted) {
        _showPdfOptionsDialog(
          pdfBytes,
          'Employee_Report.pdf',
          'Employee Report',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating employee report: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateDepartmentReport() async {
    setState(() => _isGenerating = true);

    try {
      final departments = await _departmentService.getAllDepartments();
      final employees = await _employeeService.getAllEmployees();
      final pdfBytes = await _pdfService.generateDepartmentReport(
        departments,
        employees,
      );

      // Show options dialog
      if (mounted) {
        _showPdfOptionsDialog(
          pdfBytes,
          'Department_Report.pdf',
          'Department Report',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating department report: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateSamplePayslip() async {
    setState(() => _isGenerating = true);

    try {
      final employees = await _employeeService.getAllEmployees();
      if (employees.isEmpty) {
        throw Exception('No employees found');
      }

      final employee = employees.first;
      final payslips = await _payslipService.getPayslipsByEmployee(employee.id);

      final payslip = payslips.isNotEmpty
          ? payslips.first
          : _createSamplePayslip(employee);
      final pdfBytes = await _pdfService.generatePayslip(payslip, employee);

      // Show options dialog
      if (mounted) {
        _showPdfOptionsDialog(
          pdfBytes,
          'Payslip_${employee.name.replaceAll(' ', '_')}.pdf',
          'Payslip',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating payslip: $e')));
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Payslip _createSamplePayslip(Employee employee) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final year = now.year;
    final baseSalary = (employee.salary > 0 ? employee.salary / 12 : 4500).toDouble();
    final allowances = (baseSalary * 0.2).toDouble();
    final overtime = (baseSalary * 0.05).toDouble();
    final bonus = (baseSalary * 0.1).toDouble();
    final gross = baseSalary + allowances + overtime + bonus;
    final deductions = (gross * 0.12).toDouble();
    final net = gross - deductions;

    return Payslip(
      id: 'sample-${now.millisecondsSinceEpoch}',
      employeeId: employee.id,
      employeeName: employee.name,
      month: monthName,
      year: year,
      basicSalary: baseSalary,
      allowances: allowances,
      deductions: deductions,
      netSalary: net,
      generatedDate: now,
      allowanceBreakdown: {
        'Housing Allowance': allowances * 0.5,
        'Transport Allowance': allowances * 0.3,
        'Meal Allowance': allowances * 0.2,
        'Overtime': overtime,
        'Bonus': bonus,
      },
      deductionBreakdown: {
        'Tax': deductions * 0.6,
        'Insurance': deductions * 0.3,
        'Other': deductions * 0.1,
      },
      overtime: overtime,
      bonus: bonus,
      status: 'Processed',
      currency: 'USD',
      payPeriodStart: DateTime(year, now.month, 1),
      payPeriodEnd: DateTime(year, now.month + 1, 0),
      generatedBy: 'System',
      finalizedBy: 'System',
      finalizedDate: now,
      notes: 'Sample payslip generated for demonstration purposes.',
    );
  }

  Future<void> _generateCustomReport() async {
    final config = await _showCustomReportSheet();
    if (config == null) return;

    setState(() => _isGenerating = true);

    try {
      List<Employee> employees = [];
      List<Department> departments = [];
      List<Payslip> payslips = [];

      if (config.includeEmployees) {
        employees = await _employeeService.getAllEmployees();
      }

      if (config.includeDepartments) {
        departments = await _departmentService.getAllDepartments(limit: 200);
      }

      if (config.includePayroll) {
        payslips = await _payslipService.getAllPayslips(limit: 500);

        if (config.startDate != null && config.endDate != null) {
          final start = DateTime(config.startDate!.year, config.startDate!.month, config.startDate!.day);
          final end = DateTime(config.endDate!.year, config.endDate!.month, config.endDate!.day, 23, 59, 59);

          payslips = payslips.where((payslip) {
            final monthIndex = _monthIndex(payslip.month);
            final payStart = payslip.payPeriodStart ?? DateTime(payslip.year, monthIndex, 1);
            final payEnd = payslip.payPeriodEnd ?? DateTime(payslip.year, monthIndex + 1, 0);
            return !payEnd.isBefore(start) && !payStart.isAfter(end);
          }).toList();
        }

        if (payslips.isEmpty && employees.isNotEmpty) {
          payslips = [_createSamplePayslip(employees.first)];
        }
      }

      final pdfBytes = await _pdfService.generateCustomReport(
        employees: employees,
        departments: departments,
        payslips: payslips,
        includeEmployees: config.includeEmployees,
        includeDepartments: config.includeDepartments,
        includePayroll: config.includePayroll,
        startDate: config.startDate,
        endDate: config.endDate,
      );

      if (mounted) {
        final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
        _showPdfOptionsDialog(
          pdfBytes,
          'Custom_Report_$timestamp.pdf',
          'Custom Report',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating custom report: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<_CustomReportConfig?> _showCustomReportSheet() async {
    bool includeEmployees = true;
    bool includeDepartments = true;
    bool includePayroll = true;
    DateTimeRange? dateRange;

    return showModalBottomSheet<_CustomReportConfig>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Custom Report',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: includeEmployees,
                  title: const Text('Include Employee Summary'),
                  onChanged: (value) => setModalState(() => includeEmployees = value),
                ),
                SwitchListTile(
                  value: includeDepartments,
                  title: const Text('Include Department Summary'),
                  onChanged: (value) => setModalState(() => includeDepartments = value),
                ),
                SwitchListTile(
                  value: includePayroll,
                  title: const Text('Include Payroll Summary'),
                  onChanged: (value) => setModalState(() => includePayroll = value),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Set Date Range (optional)'),
                  subtitle: Text(
                    dateRange == null
                        ? 'Tap to choose'
                        : '${DateFormat('MMM d, yyyy').format(dateRange!.start)} - ${DateFormat('MMM d, yyyy').format(dateRange!.end)}',
                  ),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(DateTime.now().year - 5),
                      lastDate: DateTime(DateTime.now().year + 1),
                      initialDateRange: dateRange,
                    );
                    if (picked != null) {
                      setModalState(() => dateRange = picked);
                    }
                  },
                  trailing: dateRange != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setModalState(() => dateRange = null),
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (!includeEmployees && !includeDepartments && !includePayroll)
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                  _CustomReportConfig(
                                    includeEmployees: includeEmployees,
                                    includeDepartments: includeDepartments,
                                    includePayroll: includePayroll,
                                    startDate: dateRange?.start,
                                    endDate: dateRange?.end,
                                  ),
                                );
                              },
                        child: const Text('Generate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _monthIndex(String monthName) {
    final months = const [
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
    final index = months.indexOf(monthName);
    return index == -1 ? DateTime.now().month : index + 1;
  }

  void _showPdfOptionsDialog(
    Uint8List pdfBytes,
    String fileName,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title Generated'),
        content: const Text('What would you like to do with the PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _pdfService.printPdf(pdfBytes, title);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error printing PDF: $e')),
                  );
                }
              }
            },
            child: const Text('Print'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final path = await _pdfService.savePdfToDevice(
                  pdfBytes,
                  fileName,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF saved to: $path')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving PDF: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _pdfService.sharePdf(pdfBytes, fileName);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sharing PDF: $e')),
                  );
                }
              }
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Generation'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PDF Generation',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate, print, save, and share PDF reports',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // PDF Generation Options
            Expanded(
              child: ListView(
                children: [
                  _buildPdfOption(
                    title: 'Employee Report',
                    description:
                        'Generate a comprehensive report of all employees',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: _generateEmployeeReport,
                  ),
                  const SizedBox(height: 16),

                  _buildPdfOption(
                    title: 'Department Report',
                    description:
                        'Generate a detailed report of all departments',
                    icon: Icons.business,
                    color: Colors.green,
                    onTap: _generateDepartmentReport,
                  ),
                  const SizedBox(height: 16),

                  _buildPdfOption(
                    title: 'Sample Payslip',
                    description: 'Generate a sample payslip for demonstration',
                    icon: Icons.receipt,
                    color: Colors.orange,
                    onTap: _generateSamplePayslip,
                  ),
                  const SizedBox(height: 16),

                  _buildPdfOption(
                    title: 'Custom Report',
                    description:
                        'Create a custom report with specific criteria',
                    icon: Icons.tune,
                    color: Colors.purple,
                    onTap: _generateCustomReport,
                  ),
                ],
              ),
            ),

            // Loading indicator
            if (_isGenerating)
              Container(
                padding: const EdgeInsets.all(16.0),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Generating PDF...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isGenerating ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomReportConfig {
  _CustomReportConfig({
    required this.includeEmployees,
    required this.includeDepartments,
    required this.includePayroll,
    this.startDate,
    this.endDate,
  });

  final bool includeEmployees;
  final bool includeDepartments;
  final bool includePayroll;
  final DateTime? startDate;
  final DateTime? endDate;
}
