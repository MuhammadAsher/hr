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
  final double overtime;
  final double bonus;
  final String status;
  final String currency;
  final DateTime? payPeriodStart;
  final DateTime? payPeriodEnd;
  final String? generatedBy;
  final String? finalizedBy;
  final DateTime? finalizedDate;
  final String? notes;
 
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
    this.overtime = 0,
    this.bonus = 0,
    this.status = 'Draft',
    this.currency = 'USD',
    this.payPeriodStart,
    this.payPeriodEnd,
    this.generatedBy,
    this.finalizedBy,
    this.finalizedDate,
    this.notes,
  });
 
   double get grossSalary => basicSalary + allowances + overtime + bonus;
 
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
       'overtime': overtime,
       'bonus': bonus,
       'status': status,
       'currency': currency,
       'payPeriodStart': payPeriodStart?.toIso8601String(),
       'payPeriodEnd': payPeriodEnd?.toIso8601String(),
       'generatedBy': generatedBy,
       'finalizedBy': finalizedBy,
       'finalizedDate': finalizedDate?.toIso8601String(),
       'notes': notes,
     };
   }
 
   factory Payslip.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    Map<String, double> _parseBreakdown(dynamic value) {
      if (value is Map) {
        return value.map((key, dynamic val) => MapEntry(
              key.toString(),
              (val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0),
            ));
      }
      return {};
    }

    return Payslip(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      month: json['month'] as String,
      year: json['year'] is int ? json['year'] as int : int.parse(json['year'].toString()),
      basicSalary: (json['basicSalary'] as num).toDouble(),
      allowances: (json['allowances'] as num).toDouble(),
      deductions: (json['deductions'] as num).toDouble(),
      netSalary: (json['netSalary'] as num).toDouble(),
      generatedDate: _parseDate(json['generatedDate']) ?? DateTime.now(),
      allowanceBreakdown: _parseBreakdown(json['allowanceBreakdown']),
      deductionBreakdown: _parseBreakdown(json['deductionBreakdown']),
      overtime: json['overtime'] != null ? (json['overtime'] as num).toDouble() : 0,
      bonus: json['bonus'] != null ? (json['bonus'] as num).toDouble() : 0,
      status: json['status']?.toString() ?? 'Draft',
      currency: json['currency']?.toString() ?? 'USD',
      payPeriodStart: _parseDate(json['payPeriodStart']),
      payPeriodEnd: _parseDate(json['payPeriodEnd']),
      generatedBy: json['generatedBy']?.toString(),
      finalizedBy: json['finalizedBy']?.toString(),
      finalizedDate: _parseDate(json['finalizedAt']),
      notes: json['notes']?.toString(),
    );
  }
}

