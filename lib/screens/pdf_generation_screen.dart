import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/pdf_service.dart';
import '../services/employee_service.dart';
import '../services/department_service.dart';
import '../services/payslip_service.dart';
import '../models/employee.dart';
import '../models/payslip.dart';

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

      if (payslips.isEmpty) {
        throw Exception('No payslips found for employee');
      }

      final payslip = payslips.first;
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
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Custom reports - Coming Soon'),
                        ),
                      );
                    },
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
