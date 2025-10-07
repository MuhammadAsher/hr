class Payslip {
  final String id;
  final String employeeId;
  final String employeeName;
  final String month;
  final int year;
  final double basicSalary;
  final double allowances;
  final double deductions;
  final double netSalary;
  final DateTime generatedDate;
  final Map<String, double> allowanceBreakdown;
  final Map<String, double> deductionBreakdown;

  Payslip({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.netSalary,
    required this.generatedDate,
    this.allowanceBreakdown = const {},
    this.deductionBreakdown = const {},
  });

  double get grossSalary => basicSalary + allowances;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'month': month,
      'year': year,
      'basicSalary': basicSalary,
      'allowances': allowances,
      'deductions': deductions,
      'netSalary': netSalary,
      'generatedDate': generatedDate.toIso8601String(),
      'allowanceBreakdown': allowanceBreakdown,
      'deductionBreakdown': deductionBreakdown,
    };
  }

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      month: json['month'] as String,
      year: json['year'] as int,
      basicSalary: (json['basicSalary'] as num).toDouble(),
      allowances: (json['allowances'] as num).toDouble(),
      deductions: (json['deductions'] as num).toDouble(),
      netSalary: (json['netSalary'] as num).toDouble(),
      generatedDate: DateTime.parse(json['generatedDate'] as String),
      allowanceBreakdown: Map<String, double>.from(
        (json['allowanceBreakdown'] as Map? ?? {}).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      deductionBreakdown: Map<String, double>.from(
        (json['deductionBreakdown'] as Map? ?? {}).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
    );
  }
}

