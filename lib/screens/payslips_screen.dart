import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payslip.dart';
import '../services/payslip_service.dart';
import '../providers/auth_provider.dart';

class PayslipsScreen extends StatefulWidget {
  const PayslipsScreen({super.key});

  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  final PayslipService _payslipService = PayslipService();
  List<Payslip> _payslips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayslips();
  }

  Future<void> _loadPayslips() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final payslips = await _payslipService.getPayslipsByEmployee(
      authProvider.currentUser!.id,
    );
    setState(() {
      _payslips = payslips;
      _isLoading = false;
    });
  }

  void _showPayslipDetails(Payslip payslip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payslip Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${payslip.month} ${payslip.year}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const Divider(height: 32),
              
              // Employee Info
              _buildSectionTitle('Employee Information'),
              _buildDetailRow('Name', payslip.employeeName),
              _buildDetailRow('Employee ID', payslip.employeeId),
              const SizedBox(height: 24),

              // Earnings
              _buildSectionTitle('Earnings'),
              _buildDetailRow('Basic Salary', '\$${payslip.basicSalary.toStringAsFixed(2)}'),
              ...payslip.allowanceBreakdown.entries.map(
                (entry) => _buildDetailRow(entry.key, '\$${entry.value.toStringAsFixed(2)}'),
              ),
              const Divider(),
              _buildDetailRow(
                'Gross Salary',
                '\$${payslip.grossSalary.toStringAsFixed(2)}',
                isBold: true,
              ),
              const SizedBox(height: 24),

              // Deductions
              _buildSectionTitle('Deductions'),
              ...payslip.deductionBreakdown.entries.map(
                (entry) => _buildDetailRow(entry.key, '\$${entry.value.toStringAsFixed(2)}'),
              ),
              const Divider(),
              _buildDetailRow(
                'Total Deductions',
                '\$${payslip.deductions.toStringAsFixed(2)}',
                isBold: true,
              ),
              const SizedBox(height: 24),

              // Net Salary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Salary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    Text(
                      '\$${payslip.netSalary.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download feature - Coming Soon')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payslips'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payslips.isEmpty
              ? const Center(child: Text('No payslips available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payslips.length,
                  itemBuilder: (context, index) {
                    final payslip = _payslips[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${payslip.month} ${payslip.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Net Salary: \$${payslip.netSalary.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showPayslipDetails(payslip),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

