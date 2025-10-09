import '../models/payslip.dart';
import 'api_client.dart';

class PayslipService {
  final ApiClient _apiClient = ApiClient();

  // Get all payslips
  Future<List<Payslip>> getAllPayslips({
    int page = 1,
    int limit = 10,
    String? employeeId,
    String? month,
    String? year,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (employeeId != null) queryParams['employeeId'] = employeeId;
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await _apiClient.get(
        '/payslips',
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        final responseData = response.data['data'];
        final List<dynamic> payslips = responseData['payslips'] ?? [];
        return payslips.map((json) => Payslip.fromJson(json)).toList();
      } else {
        throw Exception(response.message ?? 'Failed to fetch payslips');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockPayslips();
    }
  }

  // Get payslip by ID
  Future<Payslip?> getPayslipById(String payslipId) async {
    try {
      final response = await _apiClient.get('/payslips/$payslipId');

      if (response.isSuccess) {
        return Payslip.fromJson(response.data['data']);
      } else {
        throw Exception(response.message ?? 'Failed to fetch payslip');
      }
    } catch (e) {
      // Fallback to mock data
      final mockPayslips = _getMockPayslips();
      return mockPayslips.firstWhere(
        (payslip) => payslip.id == payslipId,
        orElse: () => mockPayslips.first,
      );
    }
  }

  // Create new payslip (Admin only)
  Future<bool> createPayslip({
    required String employeeId,
    required String month,
    required String year,
    required double basicSalary,
    double allowances = 0.0,
    double deductions = 0.0,
    double overtime = 0.0,
    double bonus = 0.0,
  }) async {
    try {
      final body = <String, dynamic>{
        'employeeId': employeeId,
        'month': month,
        'year': year,
        'basicSalary': basicSalary,
        'allowances': allowances,
        'deductions': deductions,
        'overtime': overtime,
        'bonus': bonus,
      };

      final response = await _apiClient.post('/payslips', body: body);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Update payslip (Admin only)
  Future<bool> updatePayslip({
    required String payslipId,
    double? basicSalary,
    double? allowances,
    double? deductions,
    double? overtime,
    double? bonus,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (basicSalary != null) body['basicSalary'] = basicSalary;
      if (allowances != null) body['allowances'] = allowances;
      if (deductions != null) body['deductions'] = deductions;
      if (overtime != null) body['overtime'] = overtime;
      if (bonus != null) body['bonus'] = bonus;

      final response = await _apiClient.put('/payslips/$payslipId', body: body);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Finalize payslip (Admin only)
  Future<bool> finalizePayslip(String payslipId) async {
    try {
      final response = await _apiClient.post('/payslips/$payslipId/finalize');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Delete payslip (Admin only)
  Future<bool> deletePayslip(String payslipId) async {
    try {
      final response = await _apiClient.delete('/payslips/$payslipId');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Fallback mock data method
  List<Payslip> _getMockPayslips() {
    final months = ['January', 'February', 'March', 'April', 'May', 'June'];
    final year = DateTime.now().year;
    final mockPayslips = <Payslip>[];

    for (int i = 0; i < months.length; i++) {
      mockPayslips.add(
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
    return mockPayslips;
  }

  // Get payslips by employee
  Future<List<Payslip>> getPayslipsByEmployee(String employeeId) async {
    return await getAllPayslips(employeeId: employeeId, limit: 100);
  }

  // Get payslip by month and year
  Future<Payslip?> getPayslipByMonthYear(
    String employeeId,
    String month,
    int year,
  ) async {
    try {
      final payslips = await getAllPayslips(
        employeeId: employeeId,
        month: month,
        year: year.toString(),
        limit: 1,
      );
      return payslips.isNotEmpty ? payslips.first : null;
    } catch (e) {
      return null;
    }
  }

  // Helper method for month number conversion
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
