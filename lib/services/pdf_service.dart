import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/employee.dart';
import '../models/payslip.dart';
import '../models/leave_request.dart';
import '../models/department.dart';
import 'package:intl/intl.dart';

class PdfService {
  // Generate Employee Report PDF
  Future<Uint8List> generateEmployeeReport(List<Employee> employees) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'Employee Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Total Employees: ${employees.length}'),
                  pw.Text(
                    'Active Employees: ${employees.where((e) => e.status == 'Active').length}',
                  ),
                  pw.Text(
                    'Departments: ${employees.map((e) => e.department).toSet().length}',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Employee Table
            pw.Text(
              'Employee Details',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Name', isHeader: true),
                    _buildTableCell('Email', isHeader: true),
                    _buildTableCell('Department', isHeader: true),
                    _buildTableCell('Position', isHeader: true),
                    _buildTableCell('Status', isHeader: true),
                  ],
                ),
                // Data rows
                ...employees.map(
                  (employee) => pw.TableRow(
                    children: [
                      _buildTableCell(employee.name),
                      _buildTableCell(employee.email),
                      _buildTableCell(employee.department),
                      _buildTableCell(employee.position),
                      _buildTableCell(employee.status),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Generate Payslip PDF
  Future<Uint8List> generatePayslip(Payslip payslip, Employee employee) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PAYSLIP',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'Pay Period: ${payslip.month}/${payslip.year}',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Employee Information
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Employee Information',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Name: ${employee.name}'),
                              pw.Text('Employee ID: ${employee.id}'),
                              pw.Text('Department: ${employee.department}'),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Position: ${employee.position}'),
                              pw.Text('Email: ${employee.email}'),
                              pw.Text(
                                'Join Date: ${employee.joinDate.day}/${employee.joinDate.month}/${employee.joinDate.year}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Earnings and Deductions
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Earnings
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Earnings',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          _buildPayslipRow('Basic Salary', payslip.basicSalary),
                          _buildPayslipRow('Allowances', payslip.allowances),
                          _buildPayslipRow(
                            'Overtime',
                            payslip.allowanceBreakdown['overtime'] ?? 0.0,
                          ),
                          pw.Divider(),
                          _buildPayslipRow(
                            'Gross Pay',
                            payslip.grossSalary,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 20),

                  // Deductions
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Deductions',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red800,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          _buildPayslipRow(
                            'Tax',
                            payslip.deductionBreakdown['tax'] ?? 0.0,
                          ),
                          _buildPayslipRow(
                            'Insurance',
                            payslip.deductionBreakdown['insurance'] ?? 0.0,
                          ),
                          _buildPayslipRow(
                            'Other',
                            payslip.deductionBreakdown['other'] ?? 0.0,
                          ),
                          pw.Divider(),
                          _buildPayslipRow(
                            'Total Deductions',
                            payslip.deductions,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Net Pay
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'NET PAY: \$${payslip.netSalary.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  'This is a computer-generated payslip and does not require a signature.',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Generate Department Report PDF
  Future<Uint8List> generateDepartmentReport(
    List<Department> departments,
    List<Employee> employees,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'Department Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Total Departments: ${departments.length}'),
                  pw.Text('Total Employees: ${employees.length}'),
                  pw.Text(
                    'Average Employees per Department: ${(employees.length / departments.length).toStringAsFixed(1)}',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Department Table
            pw.Text(
              'Department Details',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Department', isHeader: true),
                    _buildTableCell('Description', isHeader: true),
                    _buildTableCell('Manager', isHeader: true),
                    _buildTableCell('Employees', isHeader: true),
                  ],
                ),
                // Data rows
                ...departments.map(
                  (dept) => pw.TableRow(
                    children: [
                      _buildTableCell(dept.name),
                      _buildTableCell(dept.description),
                      _buildTableCell(dept.managerName ?? 'N/A'),
                      _buildTableCell('${dept.employeeCount}'),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateCustomReport({
    required List<Employee> employees,
    required List<Department> departments,
    required List<Payslip> payslips,
    required bool includeEmployees,
    required bool includeDepartments,
    required bool includePayroll,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('MMM dd, yyyy');

    final totalNetSalary = payslips.fold<double>(0, (sum, p) => sum + p.netSalary);
    final payPeriodStart = startDate != null ? dateFormatter.format(startDate) : null;
    final payPeriodEnd = endDate != null ? dateFormatter.format(endDate) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text(
                'Custom HR Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Employees Included: ${includeEmployees ? employees.length : 0}'),
                  pw.Text('Departments Included: ${includeDepartments ? departments.length : 0}'),
                  pw.Text('Payslips Included: ${includePayroll ? payslips.length : 0}'),
                  if (includePayroll && payslips.isNotEmpty)
                    pw.Text('Total Net Salary: ${NumberFormat.simpleCurrency().format(totalNetSalary)}'),
                  if (payPeriodStart != null && payPeriodEnd != null)
                    pw.Text('Date Range: $payPeriodStart - $payPeriodEnd'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ];

          if (includeEmployees) {
            widgets.addAll(_buildEmployeeSection(employees));
          }

            if (includeDepartments) {
            widgets.addAll(_buildDepartmentSection(departments));
          }

          if (includePayroll) {
            widgets.addAll(_buildPayrollSection(payslips, dateFormatter));
          }

          if (widgets.length == 3) {
            widgets.add(
              pw.Text('No data selected for the custom report.', style: pw.TextStyle(color: PdfColors.grey600)),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildEmployeeSection(List<Employee> employees) {
    if (employees.isEmpty) {
      return [
        pw.Text('Employee Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('No employee data available.', style: pw.TextStyle(color: PdfColors.grey600)),
        pw.SizedBox(height: 16),
      ];
    }

    return [
      pw.Text('Employee Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _buildTableCell('Name', isHeader: true),
              _buildTableCell('Email', isHeader: true),
              _buildTableCell('Department', isHeader: true),
              _buildTableCell('Position', isHeader: true),
              _buildTableCell('Status', isHeader: true),
            ],
          ),
          ...employees.map(
            (employee) => pw.TableRow(
              children: [
                _buildTableCell(employee.name),
                _buildTableCell(employee.email),
                _buildTableCell(employee.department),
                _buildTableCell(employee.position),
                _buildTableCell(employee.status),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 20),
    ];
  }

  List<pw.Widget> _buildDepartmentSection(List<Department> departments) {
    if (departments.isEmpty) {
      return [
        pw.Text('Department Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('No department data available.', style: pw.TextStyle(color: PdfColors.grey600)),
        pw.SizedBox(height: 16),
      ];
    }

    return [
      pw.Text('Department Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _buildTableCell('Department', isHeader: true),
              _buildTableCell('Description', isHeader: true),
              _buildTableCell('Manager', isHeader: true),
              _buildTableCell('Employees', isHeader: true),
            ],
          ),
          ...departments.map(
            (dept) => pw.TableRow(
              children: [
                _buildTableCell(dept.name),
                _buildTableCell(dept.description),
                _buildTableCell(dept.managerName ?? 'N/A'),
                _buildTableCell('${dept.employeeCount}'),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 20),
    ];
  }

  List<pw.Widget> _buildPayrollSection(
    List<Payslip> payslips,
    DateFormat dateFormatter,
  ) {
    if (payslips.isEmpty) {
      return [
        pw.Text('Payroll Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('No payroll data available.', style: pw.TextStyle(color: PdfColors.grey600)),
        pw.SizedBox(height: 16),
      ];
    }

    final totalNet = payslips.fold<double>(0, (sum, p) => sum + p.netSalary);
    final averageNet = totalNet / payslips.length;

    return [
      pw.Text('Payroll Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text('Total Net Salary: ${NumberFormat.simpleCurrency().format(totalNet)}'),
      pw.Text('Average Net Salary: ${NumberFormat.simpleCurrency().format(averageNet)}'),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(2.5),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(1.5),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _buildTableCell('Employee', isHeader: true),
              _buildTableCell('Period', isHeader: true),
              _buildTableCell('Net Salary', isHeader: true),
              _buildTableCell('Status', isHeader: true),
            ],
          ),
          ...payslips.map(
            (payslip) {
              final period = payslip.payPeriodStart != null
                  ? '${dateFormatter.format(payslip.payPeriodStart!)} - ${dateFormatter.format(payslip.payPeriodEnd ?? payslip.payPeriodStart!)}'
                  : '${payslip.month} ${payslip.year}';
              return pw.TableRow(
                children: [
                  _buildTableCell(payslip.employeeName),
                  _buildTableCell(period),
                  _buildTableCell(NumberFormat.simpleCurrency().format(payslip.netSalary)),
                  _buildTableCell(payslip.status),
                ],
              );
            },
          ),
        ],
      ),
      pw.SizedBox(height: 20),
    ];
  }

  // Helper method to build table cells
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  // Helper method to build payslip rows
  pw.Widget _buildPayslipRow(
    String label,
    double amount, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '\$${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Save PDF to device
  Future<String> savePdfToDevice(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  // Print PDF
  Future<void> printPdf(Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: title,
    );
  }

  // Share PDF
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
