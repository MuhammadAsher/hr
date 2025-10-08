class Organization {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String industry;
  final String logo; // URL or path to logo
  final DateTime registeredDate;
  final String subscriptionPlan; // Free, Basic, Premium, Enterprise
  final bool isActive;
  final int employeeLimit;
  final Map<String, dynamic> settings;
  final String adminId; // Primary organization admin
  final String taxId; // Tax identification number
  final String website;

  Organization({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.industry,
    this.logo = '',
    required this.registeredDate,
    this.subscriptionPlan = 'Free',
    this.isActive = true,
    this.employeeLimit = 10,
    this.settings = const {},
    required this.adminId,
    this.taxId = '',
    this.website = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'industry': industry,
      'logo': logo,
      'registeredDate': registeredDate.toIso8601String(),
      'subscriptionPlan': subscriptionPlan,
      'isActive': isActive,
      'employeeLimit': employeeLimit,
      'settings': settings,
      'adminId': adminId,
      'taxId': taxId,
      'website': website,
    };
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      industry: json['industry'],
      logo: json['logo'] ?? '',
      registeredDate: DateTime.parse(json['registeredDate']),
      subscriptionPlan: json['subscriptionPlan'] ?? 'Free',
      isActive: json['isActive'] ?? true,
      employeeLimit: json['employeeLimit'] ?? 10,
      settings: json['settings'] ?? {},
      adminId: json['adminId'],
      taxId: json['taxId'] ?? '',
      website: json['website'] ?? '',
    );
  }

  Organization copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? industry,
    String? logo,
    DateTime? registeredDate,
    String? subscriptionPlan,
    bool? isActive,
    int? employeeLimit,
    Map<String, dynamic>? settings,
    String? adminId,
    String? taxId,
    String? website,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      industry: industry ?? this.industry,
      logo: logo ?? this.logo,
      registeredDate: registeredDate ?? this.registeredDate,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      isActive: isActive ?? this.isActive,
      employeeLimit: employeeLimit ?? this.employeeLimit,
      settings: settings ?? this.settings,
      adminId: adminId ?? this.adminId,
      taxId: taxId ?? this.taxId,
      website: website ?? this.website,
    );
  }
}

// Subscription Plans
class SubscriptionPlan {
  static const String free = 'Free';
  static const String basic = 'Basic';
  static const String premium = 'Premium';
  static const String enterprise = 'Enterprise';

  static Map<String, int> employeeLimits = {
    free: 10,
    basic: 50,
    premium: 200,
    enterprise: -1, // Unlimited
  };

  static Map<String, double> monthlyPrices = {
    free: 0.0,
    basic: 49.99,
    premium: 149.99,
    enterprise: 499.99,
  };

  static Map<String, List<String>> features = {
    free: [
      'Up to 10 employees',
      'Basic employee management',
      'Leave management',
      'Attendance tracking',
    ],
    basic: [
      'Up to 50 employees',
      'All Free features',
      'Department management',
      'Reports & Analytics',
      'Email notifications',
    ],
    premium: [
      'Up to 200 employees',
      'All Basic features',
      'Advanced reporting',
      'PDF generation',
      'Team directory',
      'Priority support',
    ],
    enterprise: [
      'Unlimited employees',
      'All Premium features',
      'Custom integrations',
      'Dedicated support',
      'Custom branding',
      'API access',
    ],
  };
}

