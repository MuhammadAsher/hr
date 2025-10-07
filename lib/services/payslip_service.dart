import '../models/payslip.dart';

class PayslipService {
  final List<Payslip> _payslips = [];

  PayslipService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final months = ['January', 'February', 'March', 'April', 'May', 'June'];
    final year = DateTime.now().year;

    for (int i = 0; i < months.length; i++) {
      _payslips.add(
        Payslip(
          id: 'pay_${i + 1}',
          employeeId: '2',
          employeeName: 'Employee User',
          month: months[i],
          year: year,
          basicSalary: 50000,
          allowances: 15000,
          deductions: 8000,
          netSalary: 57000,
          generatedDate: DateTime(year, i + 1, 1),
          allowanceBreakdown: {
            'Housing Allowance': 8000,
            'Transport Allowance': 4000,
            'Medical Allowance': 3000,
          },
          deductionBreakdown: {
            'Tax': 5000,
            'Insurance': 2000,
            'Provident Fund': 1000,
          },
        ),
      );
    }
  }

  Future<List<Payslip>> getPayslipsByEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _payslips
        .where((payslip) => payslip.employeeId == employeeId)
        .toList()
      ..sort((a, b) {
        final dateA = DateTime(a.year, _getMonthNumber(a.month));
        final dateB = DateTime(b.year, _getMonthNumber(b.month));
        return dateB.compareTo(dateA);
      });
  }

  Future<Payslip?> getPayslipById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _payslips.firstWhere((payslip) => payslip.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Payslip?> getPayslipByMonthYear(
    String employeeId,
    String month,
    int year,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _payslips.firstWhere(
        (payslip) =>
            payslip.employeeId == employeeId &&
            payslip.month == month &&
            payslip.year == year,
      );
    } catch (e) {
      return null;
    }
  }

  int _getMonthNumber(String month) {
    const months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };
    return months[month] ?? 1;
  }
}

